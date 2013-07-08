module OrderDetail::Accessorized
  extend ActiveSupport::Concern

  included do
    belongs_to :product_accessory

    belongs_to :parent_order_detail, class_name: 'OrderDetail', :inverse_of => :child_order_details
    has_many   :child_order_details, class_name: 'OrderDetail', foreign_key: 'parent_order_detail_id', :inverse_of => :parent_order_detail

    after_save :update_children

    delegate :scaling_type, :to => :product_accessory
  end

  module ClassMethods
    # Puts parent orders first, followed by their children. Children are ordered by id
    def ordered_by_parents
      order("COALESCE(order_details.parent_order_detail_id, order_details.id), order_details.parent_order_detail_id, order_details.id")
    end
  end

  def accessories?
    product.product_accessories.any?
  end

  # Can add accessories only if the order is complete
  # and there are still accessories that haven't been added
  # (i.e. you can't add two of the same accessories--use quantity instead)
  def add_accessories?
    complete? && product.accessories.count > child_order_details.count
  end

  def quantity_as_time?
    decorated_self.quantity_as_time? #if product_accessory_id
  end

  def quantity_editable?
    decorated_self.quantity_editable?
  end

  def update_children
    accessorizer = Accessories::Accessorizer.new(self)
    accessorizer.update_children
  end

  private

  def decorated_self
    @decorated_self ||= Accessories::Scaling.decorate(self)
  end
end
