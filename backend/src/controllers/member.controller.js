import bcrypt from "bcrypt";
import { prisma } from "../config/prisma.js";

const memberSelectFields = {
  id: true,
  fullName: true,
  email: true,
  cmsId: true,
  phone: true,
  role: true,
  status: true,
  mealUnitEnabled: true,
  advanceBalance: true,
  roomId: true,
  joiningDate: true,
  createdAt: true,
  updatedAt: true,
  room: true
};

const parseJoiningDate = (value) => {
  if (!value) return null;
  if (value instanceof Date) return value;
  const raw = String(value).trim();
  if (!raw) return null;

  const ddmmyyMatch = /^(\d{2})\/(\d{2})\/(\d{2})$/.exec(raw);
  if (ddmmyyMatch) {
    const day = Number(ddmmyyMatch[1]);
    const month = Number(ddmmyyMatch[2]);
    const year = 2000 + Number(ddmmyyMatch[3]);
    return new Date(year, month - 1, day);
  }

  return new Date(raw);
};

const normalizeString = (value) => {
  if (value === undefined || value === null) return null;
  const normalized = String(value).trim();
  return normalized.length ? normalized : null;
};

const sanitizeText = (value) => {
  if (!value) return value;
  return value.replace(/[<>]/g, "");
};

const validateMemberPayload = ({ fullName, email, cmsId, password, status }, isCreate = true) => {
  if (isCreate && (!fullName || !cmsId || !email || !password)) {
    throw new Error("fullName, email, cmsId and password are required");
  }

  const safeName = fullName !== undefined ? sanitizeText(fullName) : undefined;
  const safeEmail = email !== undefined ? normalizeString(email)?.toLowerCase() : undefined;
  const safeCmsId = cmsId !== undefined ? normalizeString(cmsId) : undefined;
  const safeStatus = status !== undefined ? normalizeString(status)?.toUpperCase() : undefined;

  if (safeEmail && !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(safeEmail)) {
    throw new Error("Invalid email format");
  }

  if (safeStatus && !["ACTIVE", "INACTIVE"].includes(safeStatus)) {
    throw new Error("Invalid status. Use ACTIVE or INACTIVE");
  }

  if (isCreate && password && String(password).length < 8) {
    throw new Error("Password must be at least 8 characters long");
  }

  return {
    fullName: safeName,
    email: safeEmail,
    cmsId: safeCmsId,
    status: safeStatus
  };
};

const getRoomOccupancy = async (roomId, hostelId, excludedUserId = null, tx = prisma) => {
  return tx.user.count({
    where: {
      roomId,
      hostelId,
      role: "MEMBER",
      ...(excludedUserId ? { id: { not: excludedUserId } } : {})
    }
  });
};

export const getMembers = async (req, res) => {
  try {
    const hostelId = req.user.hostelId;
    const today = new Date();
    
    const members = await prisma.user.findMany({
      where: { role: "MEMBER", hostelId },
      select: {
        ...memberSelectFields,
        messOffPeriods: {
          where: {
            status: "ACTIVE",
            fromDate: { lte: today },
            toDate: { gte: today }
          }
        }
      },
      orderBy: {
        id: "desc"
      }
    });

    const mappedMembers = members.map((m) => {
      const isMessOff = m.messOffPeriods && m.messOffPeriods.length > 0;
      const { messOffPeriods, ...rest } = m;
      return {
        ...rest,
        status: isMessOff ? "MESS OFF" : m.status
      };
    });

    res.json({
      success: true,
      message: "Members fetched successfully",
      data: mappedMembers
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: process.env.NODE_ENV === "production" ? "Failed to fetch members" : error.message
    });
  }
};

export const createMember = async (req, res) => {
  try {
    const hostelId = req.user.hostelId;
    const {
      fullName,
      email,
      cmsId,
      phone,
      password,
      roomId,
      joiningDate,
      status,
      mealUnitEnabled
    } = req.body;

    const validated = validateMemberPayload(
      { fullName, email, cmsId, password, status },
      true
    );

    if (!validated.fullName || !validated.cmsId || !validated.email || !password) {
      return res.status(400).json({
        success: false,
        message: "fullName, email, cmsId and password are required"
      });
    }

    const existingMember = await prisma.user.findFirst({
      where: {
        hostelId,
        role: "MEMBER",
        OR: [
          { cmsId: validated.cmsId },
          ...(validated.email ? [{ email: validated.email }] : []),
          ...(phone ? [{ phone }] : [])
        ]
      }
    });

    if (existingMember) {
      return res.status(400).json({
        success: false,
        message: "Member with provided cmsId or phone already exists"
      });
    }

    const hashedPassword = await bcrypt.hash(password, 10);

    const member = await prisma.$transaction(async (tx) => {
      if (roomId) {
        const room = await tx.room.findFirst({
          where: { id: Number(roomId), hostelId }
        });
        if (!room) {
          throw new Error("Invalid room for this hostel");
        }

        const assignedMembers = await getRoomOccupancy(Number(roomId), hostelId, null, tx);
        if (assignedMembers >= room.capacity) {
          throw new Error(`Room ${room.roomNumber} is full`);
        }
      }

      const createdMember = await tx.user.create({
        data: {
          fullName: validated.fullName,
          email: validated.email || null,
          cmsId: validated.cmsId,
          phone: normalizeString(phone),
          passwordHash: hashedPassword,
          role: "MEMBER",
          hostelId,
          status: validated.status || "ACTIVE",
          mealUnitEnabled: mealUnitEnabled !== undefined ? Boolean(mealUnitEnabled) : true,
          roomId: roomId ? Number(roomId) : null,
          joiningDate: parseJoiningDate(joiningDate)
        },
        select: memberSelectFields
      });

      if (roomId) {
        const assignedMembers = await getRoomOccupancy(Number(roomId), hostelId, null, tx);
        const room = await tx.room.findUnique({ where: { id: Number(roomId) } });
        await tx.room.update({
          where: { id: Number(roomId) },
          data: {
            occupiedCount: assignedMembers,
            status:
              room?.status === "MAINTENANCE"
                ? "MAINTENANCE"
                : assignedMembers >= (room?.capacity ?? 0)
                  ? "FULL"
                  : "AVAILABLE"
          }
        });
      }

      return createdMember;
    }, { isolationLevel: "Serializable" });

    res.status(201).json({
      success: true,
      message: "Member created successfully",
      data: member
    });
  } catch (error) {
    res.status(400).json({
      success: false,
      message:
        process.env.NODE_ENV === "production"
          ? "Unable to create member"
          : error.message || "Unable to create member"
    });
  }
};

export const getMemberById = async (req, res) => {
  try {
    const hostelId = req.user.hostelId;
    const member = await prisma.user.findFirst({
      where: {
        id: Number(req.params.id),
        role: "MEMBER",
        hostelId
      },
      select: memberSelectFields
    });

    if (!member) {
      return res.status(404).json({
        success: false,
        message: "Member not found"
      });
    }

    res.json({
      success: true,
      message: "Member fetched successfully",
      data: member
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: process.env.NODE_ENV === "production" ? "Failed to fetch member" : error.message
    });
  }
};

export const updateMember = async (req, res) => {
  try {
    const hostelId = req.user.hostelId;
    const memberId = Number(req.params.id);
    const {
      fullName,
      email,
      cmsId,
      phone,
      status,
      roomId,
      joiningDate,
      mealUnitEnabled
    } = req.body;

    const validated = validateMemberPayload(
      { fullName, email, cmsId, status },
      false
    );

    const existingMember = await prisma.user.findFirst({
      where: {
        id: memberId,
        role: "MEMBER",
        hostelId
      }
    });

    if (!existingMember) {
      return res.status(404).json({
        success: false,
        message: "Member not found"
      });
    }

    if (email || cmsId || phone) {
      const duplicateMember = await prisma.user.findFirst({
        where: {
          id: { not: memberId },
          hostelId,
          role: "MEMBER",
          OR: [
            ...(validated.email ? [{ email: validated.email }] : []),
            ...(validated.cmsId ? [{ cmsId: validated.cmsId }] : []),
            ...(phone ? [{ phone }] : [])
          ]
        }
      });

      if (duplicateMember) {
        return res.status(400).json({
          success: false,
          message: "Member with provided email, cmsId or phone already exists"
        });
      }
    }

    const newRoomId = roomId !== undefined ? (roomId ? Number(roomId) : null) : existingMember.roomId;
    const oldRoomId = existingMember.roomId;

    const updatedMember = await prisma.$transaction(async (tx) => {
      if (newRoomId && oldRoomId !== newRoomId) {
        const targetRoom = await tx.room.findFirst({
          where: { id: newRoomId, hostelId }
        });
        if (!targetRoom) {
          throw new Error("Invalid room for this hostel");
        }
        const assignedMembers = await getRoomOccupancy(newRoomId, hostelId, memberId, tx);
        if (assignedMembers >= targetRoom.capacity) {
          throw new Error(`Room ${targetRoom.roomNumber} is full`);
        }
      }

      if (oldRoomId !== newRoomId) {
        if (oldRoomId) {
          const oldRoom = await tx.room.findUnique({ where: { id: oldRoomId } });
          if (oldRoom) {
            const oldRoomOccupancy = await getRoomOccupancy(oldRoomId, hostelId, memberId, tx);
            await tx.room.update({
              where: { id: oldRoomId },
              data: {
                occupiedCount: oldRoomOccupancy,
                status:
                  oldRoom.status === "MAINTENANCE"
                    ? "MAINTENANCE"
                    : oldRoomOccupancy >= oldRoom.capacity
                      ? "FULL"
                      : "AVAILABLE"
              }
            });
          }
        }
        if (newRoomId) {
          const newRoom = await tx.room.findUnique({ where: { id: newRoomId } });
          const newRoomOccupancy = await getRoomOccupancy(newRoomId, hostelId, null, tx) + 1;
          await tx.room.update({
            where: { id: newRoomId },
            data: {
              occupiedCount: newRoomOccupancy,
              status:
                newRoom?.status === "MAINTENANCE"
                  ? "MAINTENANCE"
                  : newRoomOccupancy >= (newRoom?.capacity ?? 0)
                    ? "FULL"
                    : "AVAILABLE"
            }
          });
        }
      }

      return tx.user.update({
        where: { id: memberId },
        data: {
          fullName: validated.fullName ?? existingMember.fullName,
          email: validated.email !== undefined ? (validated.email || null) : existingMember.email,
          cmsId: validated.cmsId ?? existingMember.cmsId,
          phone: phone !== undefined ? normalizeString(phone) : existingMember.phone,
          status: validated.status ?? existingMember.status,
          mealUnitEnabled: mealUnitEnabled !== undefined
            ? Boolean(mealUnitEnabled)
            : existingMember.mealUnitEnabled,
          roomId: newRoomId,
          joiningDate: joiningDate !== undefined
            ? parseJoiningDate(joiningDate)
            : existingMember.joiningDate
        },
        select: memberSelectFields
      });
    }, { isolationLevel: "Serializable" });

    res.json({
      success: true,
      message: "Member updated successfully",
      data: updatedMember
    });
  } catch (error) {
    res.status(400).json({
      success: false,
      message:
        process.env.NODE_ENV === "production"
          ? "Unable to update member"
          : error.message || "Unable to update member"
    });
  }
};

export const deleteMember = async (req, res) => {
  try {
    const hostelId = req.user.hostelId;
    const memberId = Number(req.params.id);

    const existingMember = await prisma.user.findFirst({
      where: {
        id: memberId,
        role: "MEMBER",
        hostelId
      }
    });

    if (!existingMember) {
      return res.status(404).json({
        success: false,
        message: "Member not found"
      });
    }

    await prisma.$transaction(async (tx) => {
      if (existingMember.roomId) {
        const room = await tx.room.findUnique({
          where: { id: existingMember.roomId }
        });

        if (room) {
          const updatedOccupancy = await getRoomOccupancy(
            existingMember.roomId,
            hostelId,
            memberId,
            tx
          );
          await tx.room.update({
            where: { id: existingMember.roomId },
            data: {
              occupiedCount: updatedOccupancy,
              status:
                room.status === "MAINTENANCE"
                  ? "MAINTENANCE"
                  : updatedOccupancy >= room.capacity
                    ? "FULL"
                    : "AVAILABLE"
            }
          });
        }
      }

      await tx.user.delete({
        where: { id: memberId }
      });
    });

    res.json({
      success: true,
      message: "Member deleted successfully"
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: process.env.NODE_ENV === "production" ? "Failed to delete member" : error.message
    });
  }
};