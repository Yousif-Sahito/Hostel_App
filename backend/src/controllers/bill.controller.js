import { prisma } from "../config/prisma.js";
import { generateMonthlyBillsService } from "../services/billing.service.js";

const calculatePaymentStatus = (paidAmount, dueAmount) => {
  if (paidAmount <= 0) return "UNPAID";
  if (dueAmount <= 0) return "PAID";
  return "PARTIAL";
};

export const getBills = async (req, res) => {
  try {
    const bills = await prisma.bill.findMany({
      include: {
        user: true,
        payments: true
      },
      orderBy: [
        { year: "desc" },
        { month: "desc" },
        { id: "desc" }
      ]
    });

    return res.json({
      success: true,
      message: "Bills fetched successfully",
      data: bills
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

export const generateBills = async (req, res) => {
  try {
    const { month, year, memberId } = req.body;

    if (!month || !year) {
      return res.status(400).json({
        success: false,
        message: "month and year are required"
      });
    }

    let parsedMemberId = undefined;

    if (memberId !== undefined && memberId !== null && memberId !== "") {
      const memberStr = memberId.toString().trim();
      const maybeNumber = Number(memberStr);
      
      if (!Number.isNaN(maybeNumber) && maybeNumber > 0) {
        parsedMemberId = maybeNumber;
      } else {
        // Try to find by CMS ID
        const member = await prisma.user.findFirst({
          where: { cmsId: memberStr }
        });

        if (member) {
          parsedMemberId = member.id;
        } else {
          return res.status(404).json({
            success: false,
            message: `Member not found with ID or CMS ID: ${memberStr}`
          });
        }
      }
    }

    const result = await generateMonthlyBillsService(
      Number(month),
      Number(year),
      parsedMemberId
    );

    return res.status(201).json({
      success: true,
      message: "Bills generated successfully",
      data: result
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

export const getBillsByMember = async (req, res) => {
  try {
    const memberId = Number(req.params.id);

    const bills = await prisma.bill.findMany({
      where: {
        userId: memberId
      },
      include: {
        user: true,
        payments: true
      },
      orderBy: [
        { year: "desc" },
        { month: "desc" },
        { id: "desc" }
      ]
    });

    return res.json({
      success: true,
      message: "Member bills fetched successfully",
      data: bills
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

export const getMyBills = async (req, res) => {
  try {
    const bills = await prisma.bill.findMany({
      where: {
        userId: req.user.id
      },
      include: {
        payments: true
      },
      orderBy: [
        { year: "desc" },
        { month: "desc" },
        { id: "desc" }
      ]
    });

    return res.json({
      success: true,
      message: "My bills fetched successfully",
      data: bills
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

export const updateBill = async (req, res) => {
  try {
    const id = Number(req.params.id);
    const { extraCharges, paidAmount } = req.body;

    const existing = await prisma.bill.findUnique({
      where: { id }
    });

    if (!existing) {
      return res.status(404).json({
        success: false,
        message: "Bill not found"
      });
    }

    const newExtraCharges =
      extraCharges !== undefined ? Number(extraCharges) : existing.extraCharges;

    const newPaidAmount =
      paidAmount !== undefined ? Number(paidAmount) : existing.paidAmount;

    if (Number.isNaN(newExtraCharges) || newExtraCharges < 0) {
      return res.status(400).json({
        success: false,
        message: "extraCharges must be a valid non-negative number"
      });
    }

    if (Number.isNaN(newPaidAmount) || newPaidAmount < 0) {
      return res.status(400).json({
        success: false,
        message: "paidAmount must be a valid non-negative number"
      });
    }

    const baseAmount = existing.totalAmount - existing.extraCharges;
    const newTotalAmount = baseAmount + newExtraCharges;
    const rawDueAmount = newTotalAmount - newPaidAmount;
    const newDueAmount = rawDueAmount; // Removed zero clamp

    const newStatus = calculatePaymentStatus(newPaidAmount, rawDueAmount);

    const updated = await prisma.bill.update({
      where: { id },
      data: {
        extraCharges: newExtraCharges,
        paidAmount: newPaidAmount,
        totalAmount: newTotalAmount,
        dueAmount: newDueAmount,
        paymentStatus: newStatus
      },
      include: {
        user: true,
        payments: true
      }
    });

    return res.json({
      success: true,
      message: "Bill updated successfully",
      data: updated
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: error.message
    });
  }
};