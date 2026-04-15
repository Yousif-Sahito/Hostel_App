import { prisma } from "../config/prisma.js";
import { sendPaymentReceivedNotification } from "../services/notification.service.js";

export const createPayment = async (req, res) => {
  try {
    const hostelId = req.user.hostelId;
    const { billId, amount, paymentMethod, referenceNo, notes, paymentType } = req.body;

    if (!billId || !amount || !paymentMethod) {
      return res.status(400).json({
        success: false,
        message: "billId, amount and paymentMethod are required"
      });
    }

    const bill = await prisma.bill.findUnique({
      where: { id: Number(billId) }
    });

    if (!bill || bill.hostelId !== hostelId) {
      return res.status(404).json({
        success: false,
        message: "Bill not found"
      });
    }

    const normalizedPaymentType = (paymentType || "REGULAR").toUpperCase();
    if (!["REGULAR", "ADVANCE"].includes(normalizedPaymentType)) {
      return res.status(400).json({
        success: false,
        message: "paymentType must be REGULAR or ADVANCE"
      });
    }

    const numericAmount = Number(amount);
    if (Number.isNaN(numericAmount) || numericAmount <= 0) {
      return res.status(400).json({
        success: false,
        message: "amount must be a valid positive number"
      });
    }

    const paymentDateValue = req.body.paymentDate ? new Date(req.body.paymentDate) : new Date();
    if (Number.isNaN(paymentDateValue.getTime())) {
      return res.status(400).json({
        success: false,
        message: "paymentDate must be a valid date"
      });
    }

    const payment = await prisma.$transaction(async (tx) => {
      const freshBill = await tx.bill.findFirst({
        where: { id: bill.id, hostelId }
      });

      if (!freshBill) {
        throw new Error("Bill not found");
      }

      const member = await tx.user.findFirst({
        where: { id: freshBill.userId, hostelId },
        select: { id: true, advanceBalance: true }
      });

      if (!member) {
        throw new Error("Member not found");
      }

      const dueBeforePayment = Math.max(freshBill.totalAmount - freshBill.paidAmount, 0);
      const appliedToBill = Math.min(numericAmount, dueBeforePayment);
      const overflowToAdvance = numericAmount - appliedToBill;

      const newPaidAmount = freshBill.paidAmount + appliedToBill;
      const newDueAmount = freshBill.totalAmount - newPaidAmount;

      await tx.bill.update({
        where: { id: freshBill.id },
        data: {
          paidAmount: newPaidAmount,
          dueAmount: newDueAmount,
          paymentStatus:
            newDueAmount <= 0 ? "PAID" : newPaidAmount > 0 ? "PARTIAL" : "UNPAID"
        }
      });

      const addToAdvance = overflowToAdvance > 0 ? overflowToAdvance : 0;

      let remainingAdvanceBalance = member.advanceBalance || 0;
      if (addToAdvance > 0) {
        const updatedUser = await tx.user.update({
          where: { id: member.id },
          data: {
            advanceBalance: {
              increment: addToAdvance
            }
          },
          select: { advanceBalance: true }
        });
        remainingAdvanceBalance = updatedUser.advanceBalance;
      }

      const createdPayment = await tx.payment.create({
        data: {
          billId: freshBill.id,
          hostelId,
          userId: freshBill.userId,
          amount: numericAmount,
          paymentMethod,
          paymentDate: paymentDateValue,
          referenceNo: referenceNo || null,
          notes: notes || null,
          receivedBy: req.user.id
        }
      });

      return {
        ...createdPayment,
        paymentType: normalizedPaymentType,
        appliedToBill,
        advancedAmount: addToAdvance,
        remainingAdvanceBalance
      };
    });

    const member = await prisma.user.findUnique({
      where: { id: bill.userId },
      select: { id: true, fullName: true }
    });
    if (member) {
      await sendPaymentReceivedNotification({
        memberName: member.fullName,
        amount: Number(amount),
        memberId: member.id
      });
    }

    res.status(201).json({
      success: true,
      message: "Payment recorded successfully",
      data: payment
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: process.env.NODE_ENV === "production" ? "Failed to fetch payments" : error.message
    });
  }
};

export const getPaymentsByMember = async (req, res) => {
  try {
    const hostelId = req.user.hostelId;
    const memberId = Number(req.params.id);

    const payments = await prisma.payment.findMany({
      where: {
        userId: memberId,
        hostelId
      },
      include: {
        bill: true,
        receiver: true,
        user: true
      },
      orderBy: {
        id: "desc"
      }
    });

    res.json({
      success: true,
      message: "Member payments fetched successfully",
      data: payments
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: process.env.NODE_ENV === "production" ? "Failed to create payment" : error.message
    });
  }
};

export const getAllPayments = async (req, res) => {
  try {
    const payments = await prisma.payment.findMany({
      where: { hostelId: req.user.hostelId },
      include: {
        bill: true,
        receiver: true,
        user: true
      },
      orderBy: {
        id: "desc"
      }
    });

    res.json({
      success: true,
      message: "All payments fetched successfully",
      data: payments
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: process.env.NODE_ENV === "production" ? "Failed to fetch member payment history" : error.message
    });
  }
};