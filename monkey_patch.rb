# encoding: UTF-8

class Array
  def odd_values
    self.values_at(* self.each_index.select(&:even?))
  end

  def even_values
    self.values_at(* self.each_index.select(&:odd?))
  end
end

class Object
  def format_price
    if self.nil? || !self.is_a?(Integer)
      "!"
    elsif self < 0
      "-"
    else
      "￥%.2f" % (self.to_f / 100)
    end
  end
end