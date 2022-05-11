defmodule Cutfood.CartTest do
  use ExUnit.Case

  alias Cutfood.Cart

  setup do
    on_exit(fn -> Cart.reset end)
    :ok
  end

  test "works fine when add 3 GR1, 1 SR1 and 1 CF1 products" do
    basket = ~w(GR1 SR1 GR1 GR1 CF1)
    Enum.each(basket, &Cart.add(&1))

    assert details = Cart.get_all()
    assert details["total_price"] == 22.45
  end

  test "works fine when add 2 GR1 products" do
    basket = ~w(GR1 GR1)
    Enum.each(basket, &Cart.add(&1))

    assert details = Cart.get_all()
    assert details["total_price"] == 3.11
  end

  test "works fine when add 1 GR1 and 3 SR1 products" do
    basket = ~w(GR1 SR1 SR1 SR1)
    Enum.each(basket, &Cart.add(&1))

    assert details = Cart.get_all()
    assert details["total_price"] == 16.61
  end

  test "works fine when add 1 GR1, 1 SR1 and 3 CF1 products" do
    basket = ~w(GR1 SR1 CF1 CF1 CF1)
    Enum.each(basket, &Cart.add(&1))

    assert details = Cart.get_all()
    assert details["total_price"] == 30.57
  end
end
