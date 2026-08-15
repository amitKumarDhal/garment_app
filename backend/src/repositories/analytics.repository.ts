import { supabaseAdmin } from '../config/supabase.config';

export class AnalyticsRepository {
  async getDashboardMetrics(startDate: string, endDate: string) {
    const { data: orders, error } = await supabaseAdmin
      .from('orders')
      .select('total_amount, effective_revenue, quantity, status, is_deleted')
      .gte('created_at', startDate)
      .lte('created_at', endDate)
      .eq('is_deleted', false);

    if (error) throw error;

    let periodRevenue = 0;
    let periodOrders = 0;
    let periodUnits = 0;
    const ignoredStatuses = ['Pending', 'Placed', 'Rejected', 'Deleted', 'Cancelled'];

    (orders || []).forEach((order) => {
      if (!ignoredStatuses.includes(order.status)) {
        periodOrders++;
        periodUnits += Number(order.quantity) || 0;
        const rev = Number(order.effective_revenue) > 0 ? Number(order.effective_revenue) : Number(order.total_amount);
        periodRevenue += rev;
      }
    });

    return {
      periodRevenue,
      periodOrders,
      periodUnits,
    };
  }

  async getLeaderboardData(startDate: string, endDate: string) {
    const { data: orders, error } = await supabaseAdmin
      .from('orders')
      .select('marketing_person_name, marketing_person_id, total_amount, effective_revenue, quantity, status, is_deleted')
      .gte('order_date', startDate)
      .lte('order_date', endDate)
      .eq('is_deleted', false);

    if (error) throw error;

    const agentSalesMap: Record<string, { amount: number; count: number; name: string }> = {};
    const validStatuses = [
      'Approved', 'Fab Purchased', 'Fab Ready', 'Cutting', 'Cutting Done',
      'Printing', 'Printed', 'Stitching', 'Stitched', 'Packing', 'Packed',
      'Out SRC', 'Shipping', 'Shipped', 'Delivered', 'Completed'
    ];

    (orders || []).forEach((order) => {
      if (validStatuses.includes(order.status)) {
        const agentName = order.marketing_person_name || 'Unknown';
        if (!agentSalesMap[agentName]) {
          agentSalesMap[agentName] = { amount: 0, count: 0, name: agentName };
        }
        const rev = Number(order.effective_revenue) > 0 ? Number(order.effective_revenue) : Number(order.total_amount);
        agentSalesMap[agentName].amount += rev;
        agentSalesMap[agentName].count += 1;
      }
    });

    const sortedLeaderboard = Object.values(agentSalesMap).sort((a, b) => b.amount - a.amount);
    return sortedLeaderboard;
  }
}
