import { prisma } from "../config/prisma.js";

const buildRoomPayload = (room) => {
  const occupiedCount = room.users?.length ?? room.occupiedCount ?? 0;
  const normalizedOccupiedCount = Math.max(0, occupiedCount);
  const status =
    room.status === "MAINTENANCE"
      ? "MAINTENANCE"
      : normalizedOccupiedCount >= room.capacity
        ? "FULL"
        : "AVAILABLE";

  return {
    ...room,
    occupiedCount: normalizedOccupiedCount,
    status
  };
};

export const getRooms = async (req, res) => {
  try {
    const hostelId = req.user.hostelId;
    const rooms = await prisma.room.findMany({
      where: { hostelId },
      include: {
        users: true
      },
      orderBy: {
        id: "desc"
      }
    });
    const normalizedRooms = rooms.map(buildRoomPayload);

    res.json({
      success: true,
      message: "Rooms fetched successfully",
      data: normalizedRooms
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: process.env.NODE_ENV === "production" ? "Failed to fetch rooms" : error.message
    });
  }
};

export const createRoom = async (req, res) => {
  try {
    const hostelId = req.user.hostelId;
    const { roomNumber, capacity, status } = req.body;

    if (!roomNumber || !capacity) {
      return res.status(400).json({
        success: false,
        message: "roomNumber and capacity are required"
      });
    }

    const validStatuses = ["AVAILABLE", "FULL", "MAINTENANCE"];

    if (status && !validStatuses.includes(status)) {
      return res.status(400).json({
        success: false,
        message: "Invalid room status. Use AVAILABLE, FULL, or MAINTENANCE"
      });
    }

    const existingRoom = await prisma.room.findFirst({
      where: { roomNumber, hostelId }
    });

    if (existingRoom) {
      return res.status(400).json({
        success: false,
        message: "Room already exists"
      });
    }

    const numCapacity = Number(capacity);
    if (!Number.isInteger(numCapacity) || numCapacity <= 0) {
      return res.status(400).json({
        success: false,
        message: "Capacity must be a positive number"
      });
    }

    const finalStatus = status === "MAINTENANCE" ? "MAINTENANCE" : "AVAILABLE";

    const room = await prisma.room.create({
      data: {
        roomNumber,
        hostelId,
        capacity: numCapacity,
        occupiedCount: 0,
        status: finalStatus
      }
    });

    res.status(201).json({
      success: true,
      message: "Room created successfully",
      data: room
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: process.env.NODE_ENV === "production" ? "Failed to fetch room" : error.message
    });
  }
};

export const updateRoom = async (req, res) => {
  try {
    const hostelId = req.user.hostelId;
    const roomId = Number(req.params.id);
    const { roomNumber, capacity, status } = req.body;

    const existingRoom = await prisma.room.findUnique({
      where: { id: roomId },
      include: {
        users: {
          select: { id: true }
        }
      }
    });

    if (!existingRoom || existingRoom.hostelId !== hostelId) {
      return res.status(404).json({
        success: false,
        message: "Room not found"
      });
    }

    const actualOccupiedCount = existingRoom.users.length;
    const newCapacity = capacity !== undefined ? Number(capacity) : existingRoom.capacity;

    if (!Number.isInteger(newCapacity) || newCapacity <= 0) {
      return res.status(400).json({
        success: false,
        message: "Capacity must be a positive number"
      });
    }

    if (newCapacity < actualOccupiedCount) {
      return res.status(400).json({
        success: false,
        message: `Capacity cannot be less than current occupied count (${actualOccupiedCount})`
      });
    }

    const finalStatus =
      status === "MAINTENANCE"
        ? "MAINTENANCE"
        : actualOccupiedCount >= newCapacity
          ? "FULL"
          : "AVAILABLE";

    const room = await prisma.room.update({
      where: { id: roomId },
      data: {
        roomNumber: roomNumber ?? existingRoom.roomNumber,
        capacity: newCapacity,
        occupiedCount: actualOccupiedCount,
        status: finalStatus
      }
    });

    res.json({
      success: true,
      message: "Room updated successfully",
      data: room
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: process.env.NODE_ENV === "production" ? "Failed to create room" : error.message
    });
  }
};

export const deleteRoom = async (req, res) => {
  try {
    const hostelId = req.user.hostelId;
    const roomId = Number(req.params.id);

    const existingRoom = await prisma.room.findUnique({
      where: { id: roomId }
    });

    if (!existingRoom || existingRoom.hostelId !== hostelId) {
      return res.status(404).json({
        success: false,
        message: "Room not found"
      });
    }

    await prisma.$transaction(async (tx) => {
      await tx.user.updateMany({
        where: { roomId: roomId, hostelId },
        data: { roomId: null }
      });

      await tx.room.delete({
        where: { id: roomId }
      });
    });

    res.json({
      success: true,
      message: "Room deleted successfully"
    });

  } catch (error) {
    res.status(500).json({
      success: false,
      message: process.env.NODE_ENV === "production" ? "Failed to update room" : error.message
    });
  }
};