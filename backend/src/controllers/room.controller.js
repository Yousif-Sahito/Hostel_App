import { prisma } from "../config/prisma.js";

export const getRooms = async (req, res) => {
  try {
    const rooms = await prisma.room.findMany({
      include: {
        users: true
      },
      orderBy: {
        id: "desc"
      }
    });

    res.json({
      success: true,
      message: "Rooms fetched successfully",
      data: rooms
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

export const createRoom = async (req, res) => {
  try {
    const { roomNumber, capacity, occupiedCount = 0, status } = req.body;

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

    const existingRoom = await prisma.room.findUnique({
      where: { roomNumber }
    });

    if (existingRoom) {
      return res.status(400).json({
        success: false,
        message: "Room already exists"
      });
    }

    const numCapacity = Number(capacity);
    const numOccupiedCount = Number(occupiedCount);
    
    // Auto-calculate status if not provided
    let finalStatus = status || "AVAILABLE";
    if (!status && numOccupiedCount >= numCapacity) {
      finalStatus = "FULL";
    }

    const room = await prisma.room.create({
      data: {
        roomNumber,
        capacity: numCapacity,
        occupiedCount: numOccupiedCount,
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
      message: error.message
    });
  }
};

export const updateRoom = async (req, res) => {
  try {
    const roomId = Number(req.params.id);
    const { roomNumber, capacity, occupiedCount, status } = req.body;

    const existingRoom = await prisma.room.findUnique({
      where: { id: roomId }
    });

    if (!existingRoom) {
      return res.status(404).json({
        success: false,
        message: "Room not found"
      });
    }

    const newCapacity = capacity !== undefined ? Number(capacity) : existingRoom.capacity;
    const newOccupiedCount = occupiedCount !== undefined ? Number(occupiedCount) : existingRoom.occupiedCount;
    
    // Auto-calculate status based on occupied count vs capacity
    let finalStatus = status;
    if (!status) {
      finalStatus = newOccupiedCount >= newCapacity ? "FULL" : "AVAILABLE";
    }

    const room = await prisma.room.update({
      where: { id: roomId },
      data: {
        roomNumber: roomNumber ?? existingRoom.roomNumber,
        capacity: newCapacity,
        occupiedCount: newOccupiedCount,
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
      message: error.message
    });
  }
};

export const deleteRoom = async (req, res) => {
  try {
    const roomId = Number(req.params.id);

    const existingRoom = await prisma.room.findUnique({
      where: { id: roomId }
    });

    if (!existingRoom) {
      return res.status(404).json({
        success: false,
        message: "Room not found"
      });
    }

    await prisma.$transaction(async (tx) => {
      await tx.user.updateMany({
        where: { roomId: roomId },
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
      message: error.message
    });
  }
};