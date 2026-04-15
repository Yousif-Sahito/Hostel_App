import { prisma } from "../config/prisma.js";

export const getMyNotifications = async (req, res) => {
  try {
    const notifications = await prisma.notification.findMany({
      where: { userId: req.user.id, hostelId: req.user.hostelId },
      orderBy: { createdAt: "desc" },
      take: 100
    });

    return res.json({
      success: true,
      message: "Notifications fetched successfully",
      data: notifications
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: process.env.NODE_ENV === "production" ? "Failed to fetch notifications" : error.message
    });
  }
};

export const getUnreadCount = async (req, res) => {
  try {
    const count = await prisma.notification.count({
      where: {
        userId: req.user.id,
        hostelId: req.user.hostelId,
        isRead: false
      }
    });

    return res.json({
      success: true,
      message: "Unread count fetched successfully",
      data: { unreadCount: count }
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: process.env.NODE_ENV === "production" ? "Failed to fetch unread notification count" : error.message
    });
  }
};

export const markNotificationAsRead = async (req, res) => {
  try {
    const notificationId = Number(req.params.id);
    const notification = await prisma.notification.findFirst({
      where: {
        id: notificationId,
        userId: req.user.id,
        hostelId: req.user.hostelId
      }
    });

    if (!notification) {
      return res.status(404).json({
        success: false,
        message: "Notification not found"
      });
    }

    const updated = await prisma.notification.update({
      where: { id: notificationId },
      data: {
        isRead: true,
        readAt: new Date()
      }
    });

    return res.json({
      success: true,
      message: "Notification marked as read",
      data: updated
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: process.env.NODE_ENV === "production" ? "Failed to mark notification as read" : error.message
    });
  }
};

export const markAllNotificationsAsRead = async (req, res) => {
  try {
    await prisma.notification.updateMany({
      where: {
        userId: req.user.id,
        hostelId: req.user.hostelId,
        isRead: false
      },
      data: {
        isRead: true,
        readAt: new Date()
      }
    });

    return res.json({
      success: true,
      message: "All notifications marked as read"
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: process.env.NODE_ENV === "production" ? "Failed to mark all notifications as read" : error.message
    });
  }
};
