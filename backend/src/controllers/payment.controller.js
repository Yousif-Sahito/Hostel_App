import { prisma } from "../config/prisma.js";

export const createPayment = async (req, res) => {
  try {
    const { billId, amount, paymentMethod, referenceNo, notes } = req.body;

    if (!billId || !amount || !paymentMethod) {
      return res.status(400).json({
        success: false,
        message: "billId, amount and paymentMethod are required"
      });
    }

    const bill = await prisma.bill.findUnique({
      where: { id: Number(billId) }
    });

    if (!bill) {
      return res.status(404).json({
        success: false,
        message: "Bill not found"
      });
    }

    const payment = await prisma.payment.create({
      data: {
        billId: bill.id,
        userId: bill.userId,
        amount: Number(amount),
        paymentMethod,
        paymentDate: new Date(),
        referenceNo: referenceNo || null,
        notes: notes || null,
        receivedBy: req.user.id
      }
    });

    const newPaidAmount = bill.paidAmount + Number(amount);
    const newDueAmount = bill.totalAmount - newPaidAmount;

    await prisma.bill.update({
      where: { id: bill.id },
      data: {
        paidAmount: newPaidAmount,
        dueAmount: newDueAmount,
        paymentStatus:
          newDueAmount <= 0 ? "PAID" : newPaidAmount > 0 ? "PARTIAL" : "UNPAID"
      }
    });

    res.status(201).json({
      success: true,
      message: "Payment recorded successfully",
      data: payment
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

export const getPaymentsByMember = async (req, res) => {
  try {
    const memberId = Number(req.params.id);

    const payments = await prisma.payment.findMany({
      where: {
        userId: memberId
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
      message: error.message
    });
  }
};

export const getAllPayments = async (req, res) => {
  try {
    const payments = await prisma.payment.findMany({
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
      message: error.message
    });
  }
};