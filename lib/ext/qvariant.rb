# see: https://techbase.kde.org/Development/Languages/Ruby#Alternate_way_to_emit_Ruby_Classes
class Object
  def to_variant
    Qt::Variant.new object_id.to_s
  end
end

class Qt::Variant
  def to_object
    ObjectSpace._id2ref to_string.to_i
  end
end