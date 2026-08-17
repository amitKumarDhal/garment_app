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

    const orderData = {
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

    // 2. If advance payment collected, create payment_request
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

    const updatePayload: Record<string, any> = {
      last_updated_by: user.name,
    };

    if (data.clientName) updatePayload.client_name = data.clientName.trim();
    if (data.clientPhone !== undefined) updatePayload.client_phone = data.clientPhone?.trim() || null;
    if (data.organization !== undefined) updatePayload.organization = data.organization?.trim() || null;
    if (data.clientAddress !== undefined) updatePayload.client_address = data.clientAddress?.trim() || null;
    if (data.clientGstNumber !== undefined) updatePayload.client_gst_number = data.clientGstNumber?.trim() || null;
    if (data.pincode) updatePayload.pincode = data.pincode;
    if (data.state) updatePayload.state = data.state;
    if (data.deliveryDate) updatePayload.delivery_date = data.deliveryDate;
    if (data.mockupUrl !== undefined) updatePayload.mockup_url = data.mockupUrl;
    if (data.productDetails || data.product_details) {
      updatePayload.product_details = data.productDetails || data.product_details;
    }
    if (data.status) updatePayload.status = data.status;

    // Financial calculations
    if (data.products && data.products.length > 0) {
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

      const shipping = data.shippingCharge !== undefined ? Number(data.shippingCharge) : Number(existing.shipping_charge || 0);
      const advance = data.advanceAmount !== undefined ? Number(data.advanceAmount) : Number(existing.advance_amount || 0);
      const grandTotal = subTotal + totalTax + shipping;
      const balanceDue = grandTotal - advance;

      updatePayload.quantity = totalQty;
      updatePayload.shipping_charge = shipping;
      updatePayload.advance_amount = advance;
      updatePayload.total_amount = grandTotal;
      updatePayload.balance_due = balanceDue;
      updatePayload.effective_revenue = grandTotal;
      updatePayload.gst_percentage = data.products[0]?.gstPercentage || existing.gst_percentage || 0;

      const firstProdName = data.products[0]?.productName || existing.product_name;
      updatePayload.product_name = data.products.length > 1 ? `${firstProdName} + ${data.products.length - 1} more` : firstProdName;

      return this.orderRepo.updateOrderWithItems(id, updatePayload, data.products);
    } else if (data.quantity !== undefined || data.total_amount !== undefined || data.totalAmount !== undefined) {
      const newQty = Number(data.quantity) || existing.quantity;
      const newTotal = Number(data.total_amount ?? data.totalAmount) || existing.total_amount;
      const advance = Number(existing.advance_amount || 0);
      const newBalance = newTotal - advance;

      updatePayload.quantity = newQty;
      updatePayload.total_amount = newTotal;
      updatePayload.balance_due = newBalance;
      updatePayload.effective_revenue = newTotal;

      return this.orderRepo.updateOrderWithItems(id, updatePayload);
    }

    return this.orderRepo.updateOrderWithItems(id, updatePayload);
  }

  async updateOrderStatus(id: string, status: string, user: AuthUser, extraFields: Record<string, any> = {}) {
    const order = await this.orderRepo.findById(id);
    if (!order) throw ApiError.notFound('Order not found');

    return this.orderRepo.updateStatus(id, status, user.name, extraFields);
  }

  async approveOrder(id: string, user: AuthUser, approvalData: { effectiveRevenue?: number; marginNumber?: number }) {
    const order = await this.orderRepo.findById(id);
    if (!order) throw ApiError.notFound('Order not found');

    const updatePayload: Record<string, any> = {};
    if (approvalData.effectiveRevenue) {
      updatePayload.effective_revenue = approvalData.effectiveRevenue;
    }

    const updated = await this.orderRepo.updateStatus(id, 'Approved', user.name, updatePayload);

    // Notify agent
    if (order.marketing_person_id) {
      await this.notificationRepo.createNotification({
        target_user_id: order.marketing_person_id,
        title: 'Order Update ✅',
        message: `Order ${order.manual_order_no} has been approved by ${user.name}.`,
        type: 'OrderApproved',
        order_id: order.id,
      });
    }

    return updated;
  }

  async rejectOrder(id: string, user: AuthUser) {
    const order = await this.orderRepo.findById(id);
    if (!order) throw ApiError.notFound('Order not found');

    const updated = await this.orderRepo.updateStatus(id, 'Rejected', user.name);

    if (order.marketing_person_id) {
      await this.notificationRepo.createNotification({
        target_user_id: order.marketing_person_id,
        title: 'Order Rejected ❌',
        message: `Order ${order.manual_order_no} was rejected.`,
        type: 'OrderRejected',
        order_id: order.id,
      });
    }

    return updated;
  }

  async deleteOrder(id: string, user: AuthUser) {
    const order = await this.orderRepo.findById(id);
    if (!order) throw ApiError.notFound('Order not found');

    return this.orderRepo.deleteOrder(id, true);
  }

  async requestDeletion(id: string, user: AuthUser) {
    const order = await this.orderRepo.findById(id);
    if (!order) throw ApiError.notFound('Order not found');

    const lockedStatuses = ['Shipping', 'Shipped', 'Delivered', 'Completed'];
    if (lockedStatuses.includes(order.status)) {
      throw ApiError.badRequest(`Cannot delete order in ${order.status} stage.`);
    }

    return this.orderRepo.requestDeletion(id);
  }
}
