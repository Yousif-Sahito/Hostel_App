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
  roomId: true,
  joiningDate: true,
  createdAt: true,
  updatedAt: true,
  room: true
};

export const getMembers = async (req, res) => {
  try {
    const today = new Date();
    
    const members = await prisma.user.findMany({
      where: { role: "MEMBER" },
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
      message: error.message
    });
  }
};

export const createMember = async (req, res) => {
  try {
    const {
      fullName,
      email,
      cmsId,
      phone,
      password,
      roomId,
      joiningDate
    } = req.body;

    if (!fullName || !cmsId || !password) {
      return res.status(400).json({
        success: false,
        message: "fullName, cmsId and password are required"
      });
    }

    const existingMember = await prisma.user.findFirst({
      where: {
        OR: [
          { cmsId },
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

    const member = await prisma.user.create({
      data: {
        fullName,
        email: email || null,
        cmsId,
        phone: phone || null,
        passwordHash: hashedPassword,
        role: "MEMBER",
        status: "ACTIVE",
        roomId: roomId ? Number(roomId) : null,
        joiningDate: joiningDate ? new Date(joiningDate) : null
      },
      select: memberSelectFields
    });

    if (roomId) {
      await prisma.room.update({
        where: { id: Number(roomId) },
        data: {
          occupiedCount: {
            increment: 1
          }
        }
      });
    }

    res.status(201).json({
      success: true,
      message: "Member created successfully",
      data: member
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

export const getMemberById = async (req, res) => {
  try {
    const member = await prisma.user.findFirst({
      where: {
        id: Number(req.params.id),
        role: "MEMBER"
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
      message: error.message
    });
  }
};

export const updateMember = async (req, res) => {
  try {
    const memberId = Number(req.params.id);
    const { fullName, phone, status, roomId, joiningDate } = req.body;

    const existingMember = await prisma.user.findFirst({
      where: {
        id: memberId,
        role: "MEMBER"
      }
    });

    if (!existingMember) {
      return res.status(404).json({
        success: false,
        message: "Member not found"
      });
    }

    const newRoomId = roomId !== undefined ? (roomId ? Number(roomId) : null) : existingMember.roomId;
    const oldRoomId = existingMember.roomId;

    const updatedMember = await prisma.$transaction(async (tx) => {
      // Update room occupiedCount if room changed
      if (oldRoomId !== newRoomId) {
        if (oldRoomId) {
          const oldRoom = await tx.room.findUnique({ where: { id: oldRoomId } });
          if (oldRoom && oldRoom.occupiedCount > 0) {
            await tx.room.update({
              where: { id: oldRoomId },
              data: { occupiedCount: { decrement: 1 } }
            });
          }
        }
        if (newRoomId) {
          await tx.room.update({
            where: { id: newRoomId },
            data: { occupiedCount: { increment: 1 } }
          });
        }
      }

      return tx.user.update({
        where: { id: memberId },
        data: {
          fullName: fullName ?? existingMember.fullName,
          phone: phone ?? existingMember.phone,
          status: status ?? existingMember.status,
          roomId: newRoomId,
          joiningDate: joiningDate ? new Date(joiningDate) : existingMember.joiningDate
        },
        select: memberSelectFields
      });
    });

    res.json({
      success: true,
      message: "Member updated successfully",
      data: updatedMember
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

export const deleteMember = async (req, res) => {
  try {
    const memberId = Number(req.params.id);

    const existingMember = await prisma.user.findFirst({
      where: {
        id: memberId,
        role: "MEMBER"
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

        if (room && room.occupiedCount > 0) {
          await tx.room.update({
            where: { id: existingMember.roomId },
            data: {
              occupiedCount: {
                decrement: 1
              }
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
      message: error.message
    });
  }
};