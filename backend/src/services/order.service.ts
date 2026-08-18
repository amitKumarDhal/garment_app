import { OrderRepository } from '../repositories/order.repository';
import { PaymentRepository } from '../repositories/payment.repository';
import { NotificationRepository } from '../repositories/notification.repository';
import { UserRepository } from '../repositories/user.repository';
import { ApiError } from '../utils/apiError';
import { AuthUser } from '../types';

export class OrderService {
  private orderRepo = new OrderRepository();
  private paymentRepo = new PaymentRepository();
  private notificationRepo = new NotificationRepository();
  private userRepo = new UserRepository();

  async getOrders(user: AuthUser, statusFilter?: string[]) {
    if (user.role === 'SALES_ASSOCIATE') {
      return this.orderRepo.findAll({ marketingPersonId: user.id, status: statusFilter });
    }
    return this.orderRepo.findAll({ status: statusFilter });
  }

  async getOrderById(id: string) {
    const order = await this.orderRepo.findById(id);
    if (!order) throw ApiError.notFound('Order not found');
    return order;
  }

  async getLastSerial() {
    const serialInfo = await this.orderRepo.getLatestOrderSerial();
    return {
      lastSerial: serialInfo.lastSerial,
      nextSerial: serialInfo.nextSerial,
      formattedLastSerial: serialInfo.formattedLastSerial,
      formattedNextSerial: serialInfo.formattedNextSerial,
      serial: serialInfo.formattedNextSerial,
      lastOrderNo: serialInfo.formattedLastSerial,
      nextOrderNo: serialInfo.formattedNextSerial,
    };
  }

  async createOrder(data: any, user: AuthUser) {
    // 1. Calculate server-side order total & tax math
    let subTotal = 0;
    let totalTax = 0;
    let totalQty = 0;

    data.products.forEach((prod: any) => {
      const price = Number(prod.price) || 0;
      const qty = Number(prod.qty) || 1;
      const gstPct = Number(prod.gstPercentage) || 0;

      const base = price * qty;
      const tax = base * (gstPct / 100);

      subTotal += base;
      totalTax += tax;
      totalQty += qty;
    });

    const shipping = Number(data.shippingCharge) || 0;
    const advance = Number(data.advanceAmount) || 0;
    const grandTotal = subTotal + totalTax + shipping;
    const balanceDue = grandTotal - advance;

    const initialStatus = 'Pending';
    const firstProdName = data.products[0]?.productName || 'Garments';
    const rootProdName = data.products.length > 1 ? `${firstProdName} + ${data.products.length - 1} more` : firstProdName;

    // 2. Authoritative serial generation from backend database state
    const serialInfo = await this.orderRepo.getLatestOrderSerial();

    const orderData = {
      manual_order_no: serialInfo.formattedNextSerial,
      client_name: data.clientName.trim(),
      client_phone: data.clientPhone?.trim() || null,
      organization: data.organization?.trim() || null,
      client_address: data.clientAddress?.trim() || null,
      client_gst_number: data.clientGstNumber?.trim() || null,
      pincode: data.pincode,
      state: data.state,
      product_code: data.products[0]?.productCode || null,
      product_name: rootProdName,
      product_details: rootProdName,
      quantity: totalQty,
      priority: data.priority || 'Medium',
      status: initialStatus,
      total_amount: grandTotal,
      gst_percentage: data.products[0]?.gstPercentage || 0,
      shipping_charge: shipping,
      advance_amount: advance,
      balance_due: balanceDue,
      effective_revenue: grandTotal,
      marketing_person_id: user.id,
      marketing_person_name: user.name,
      mockup_url: data.mockupUrl || null,
      delivery_date: data.deliveryDate,
    };

    const newOrder = await this.orderRepo.createOrderWithItems(orderData, data.products);

    // 3. If advance payment collected, create payment_request
    if (advance > 0) {
      await this.paymentRepo.createRequest({
        order_id: newOrder.id,
        manual_order_no: newOrder.manual_order_no,
        client_name: newOrder.client_name,
        agent_name: user.name,
        amount: advance,
        status: 'pending',
      });
    }

    return newOrder;
  }

  async updateOrder(id: string, data: any, user: AuthUser) {
    const existing = await this.orderRepo.findById(id);
    if (!existing) throw ApiError.notFound('Order not found');

    if (user.role === 'SALES_ASSOCIATE') {
      if (existing.marketing_person_id !== user.id) {
        throw ApiError.forbidden('You can only edit your own orders');
      }
      if (existing.status !== 'Pending') {
        throw ApiError.forbidden('Orders can only be edited while in Pending status');
      }
    }

    let subTotal = 0;
    let totalTax = 0;
    let totalQty = 0;

    if (data.products && data.products.length > 0) {
      data.products.forEach((prod: any) => {
        const price = Number(prod.price) || 0;
        const qty = Number(prod.qty) || 1;
        const gstPct = Number(prod.gstPercentage) || 0;

        const base = price * qty;
        const tax = base * (gstPct / 100);

        subTotal += base;
        totalTax += tax;
        totalQty += qty;
      });
    }

    const shipping = data.shippingCharge !== undefined ? Number(data.shippingCharge) : existing.shipping_charge;
    const advance = data.advanceAmount !== undefined ? Number(data.advanceAmount) : existing.advance_amount;
    const grandTotal = (data.products && data.products.length > 0) ? (subTotal + totalTax + shipping) : existing.total_amount;
    const balanceDue = grandTotal - advance;

    const firstProdName = data.products && data.products.length > 0 ? (data.products[0]?.productName || 'Garments') : existing.product_name;
    const rootProdName = data.products && data.products.length > 1 ? `${firstProdName} + ${data.products.length - 1} more` : firstProdName;

    const updatePayload: Record<string, any> = {
      client_name: data.clientName ? data.clientName.trim() : existing.client_name,
      client_phone: data.clientPhone !== undefined ? (data.clientPhone ? data.clientPhone.trim() : null) : existing.client_phone,
      organization: data.organization !== undefined ? (data.organization ? data.organization.trim() : null) : existing.organization,
      client_address: data.clientAddress !== undefined ? (data.clientAddress ? data.clientAddress.trim() : null) : existing.client_address,
      client_gst_number: data.clientGstNumber !== undefined ? (data.clientGstNumber ? data.clientGstNumber.trim() : null) : existing.client_gst_number,
      pincode: data.pincode !== undefined ? data.pincode : existing.pincode,
      state: data.state !== undefined ? data.state : existing.state,
      delivery_date: data.deliveryDate !== undefined ? data.deliveryDate : existing.delivery_date,
      shipping_charge: shipping,
      advance_amount: advance,
      total_amount: grandTotal,
      balance_due: balanceDue,
      effective_revenue: grandTotal,
      product_name: rootProdName,
      product_details: rootProdName,
      quantity: totalQty > 0 ? totalQty : existing.quantity,
      mockup_url: data.mockupUrl !== undefined ? data.mockupUrl : existing.mockup_url,
    };

    return this.orderRepo.updateOrderWithItems(id, updatePayload, data.products);
  }

  async updateOrderStatus(id: string, newStatus: string, user: AuthUser, extraFields: Record<string, any> = {}) {
    const existing = await this.orderRepo.findById(id);
    if (!existing) throw ApiError.notFound('Order not found');

    const updated = await this.orderRepo.updateStatus(id, newStatus, user.name, extraFields);

    if (newStatus === 'Production') {
      await this.notificationRepo.createNotification({
        target_user_id: existing.marketing_person_id,
        order_id: id,
        title: 'Order Moved to Production',
        message: `Order #${existing.manual_order_no} for ${existing.client_name} has moved to Production.`,
        type: 'production_started',
      });
    } else if (newStatus === 'Dispatched') {
      await this.notificationRepo.createNotification({
        target_user_id: existing.marketing_person_id,
        order_id: id,
        title: 'Order Dispatched',
        message: `Order #${existing.manual_order_no} has been dispatched.`,
        type: 'order_dispatched',
      });
    }

    return updated;
  }

  async approveOrder(id: string, user: AuthUser, approvalData: { effectiveRevenue?: number; marginNumber?: number; approvalNotes?: string }) {
    const existing = await this.orderRepo.findById(id);
    if (!existing) throw ApiError.notFound('Order not found');
    if (existing.status !== 'Pending') {
      throw ApiError.badRequest('Only Pending orders can be approved');
    }

    const payload: Record<string, any> = {
      status: 'Approved',
      approved_by_id: user.id,
      approved_by_name: user.name,
      approved_at: new Date().toISOString(),
      last_updated_by: user.name,
      updated_at: new Date().toISOString(),
    };

    if (approvalData.effectiveRevenue !== undefined) {
      payload.effective_revenue = approvalData.effectiveRevenue;
    }
    if (approvalData.marginNumber !== undefined) {
      payload.margin_number = approvalData.marginNumber;
    }
    if (approvalData.approvalNotes) {
      payload.approval_notes = approvalData.approvalNotes;
    }

    const updated = await this.orderRepo.updateOrderWithItems(id, payload);

    await this.notificationRepo.createNotification({
      target_user_id: existing.marketing_person_id,
      order_id: id,
      title: 'Order Approved',
      message: `Your Order #${existing.manual_order_no} (${existing.client_name}) has been Approved!`,
      type: 'order_approved',
    });

    return updated;
  }

  async rejectOrder(id: string, user: AuthUser) {
    const existing = await this.orderRepo.findById(id);
    if (!existing) throw ApiError.notFound('Order not found');

    const updated = await this.orderRepo.updateOrderWithItems(id, {
      status: 'Cancelled',
      last_updated_by: user.name,
      updated_at: new Date().toISOString(),
    });

    await this.notificationRepo.createNotification({
      target_user_id: existing.marketing_person_id,
      order_id: id,
      title: 'Order Rejected',
      message: `Order #${existing.manual_order_no} has been rejected/cancelled.`,
      type: 'order_rejected',
    });

    return updated;
  }

  async deleteOrder(id: string, user: AuthUser) {
    const existing = await this.orderRepo.findById(id);
    if (!existing) throw ApiError.notFound('Order not found');

    if (user.role !== 'ADMIN' && user.role !== 'SALES_MANAGER') {
      throw ApiError.forbidden('Only Admins or Sales Managers can delete orders');
    }

    return this.orderRepo.deleteOrder(id, true);
  }

  async requestDeletion(id: string, user: AuthUser) {
    const existing = await this.orderRepo.findById(id);
    if (!existing) throw ApiError.notFound('Order not found');

    return this.orderRepo.requestDeletion(id);
  }
}
