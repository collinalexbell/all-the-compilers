##
# Mixin used to identify classes which have no memory storage.

module ImmediateValue
  def singleton_methods(all=true)
    []
  end

  def public_singleton_methods
    []
  end
  private :public_singleton_methods

  def private_singleton_methods
    []
  end
  private :private_singleton_methods

  def protected_singleton_methods
    []
  end
  private :protected_singleton_methods

  def dup
    raise TypeError, "can't dup #{self.class.name}"
  end

  def clone
    raise TypeError, "can't clone #{self.class.name}"
  end
end
