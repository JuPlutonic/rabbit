# frozen_string_literal: true

# app/model/work_order.rb pushes information to
# # the work_orders_collector - external script.
def create
  # Stores work order
  # in database
  @work_order = WorkOrder.new(params[:work_order])
  @work_order.save!

  # Queues message to
  # process work order
  mq = ReliableMsg::Queue.new('orders_queue')
  message = WorkOrderMessage.new(params[:work_order])
  # OPTIMIZE: .put blocks Rails app when placing the message in the queue!
  #
  # OPTIMIZE: Use AP4R or ActiveMessaging(better, provide many MQ-brokers).
  # OPTIMIZE: Easier, but not powerful to use Spawn or BackgrounDRb to handle
  #           the sending (and optionally in work_order_collector.rb consuming
  #           of messages).
  mq.put message

  flash[:notice] = 'Work order submitted.'
  # to the index of the work_orders controller
  redirect_to(work_orders_path)
rescue ActiveRecord::RecordInvalid
  render action: 'new'
end
