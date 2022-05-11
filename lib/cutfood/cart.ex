defmodule Cutfood.Cart do
  use GenServer

  # Public APIs
  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @doc """
  Add new product to cart if exist other wise raise an error "invalid prduct"
  """
  def add(code) do
    GenServer.call(__MODULE__, {:add, code})
  end

  @doc """
  Delete product from cart
  """
  def delete(code) do
    GenServer.call(__MODULE__, {:delete, code})
  end

  @doc """
  Get all products with details
  """
  def get_all() do
    GenServer.call(__MODULE__, :get_all)
  end

  @doc """
  Reset state
  """
  def reset() do
    GenServer.call(__MODULE__, :reset)
  end

  # CallBacks
  @impl true
  def init(stack) do
    {:ok, stack}
  end

  @impl true
  def handle_call({:add, code}, _from, state) do
    state = build_state(code, state, :+)
    {:reply, state, state}
  end

  def handle_call({:delete, code}, _from, state) do
    state = build_state(code, state, :-)
    {:reply, state, state}
  end

  def handle_call(:get_all, _from, state) do
    {:reply, state, state}
  end

  def handle_call(:reset, _from, _state) do
    {:reply, %{}, %{}}
  end

  # Dummy records, in real time we will have database containing discounts table & products tabel
  # There are two types og discounts for now. One is BAGM => Buy And Get More and second is
  # PERC => Percentage type
  def discounts() do
    %{
      "1" => %{id: 1, percentage: nil, after_items: 1, type: "BAGM", buy: 1, get: 1},
      "2" => %{id: 2, percentage: 10, after_items: 3, type: "PERC", buy: nil, get: nil},
      "3" => %{id: 3, percentage: 33.34, after_items: 3, type: "PERC", buy: nil, get: nil}
    }
  end

  def products() do
    %{
      "GR1" => %{price: 3.11, discount_id: 1, code: "GR1", name: "Green tea"},
      "SR1" => %{price: 5, discount_id: 2, code: "SR1", name: "Strawberries"},
      "CF1" => %{price: 11.23, discount_id: 3, code: "CF1", name: "Coffee"}
    }
  end

  # Helpers
  defp build_state(code, state, operation) do
    product = Map.get(products(), code) || raise "invalid product code"

    {_, state} =
      product
      |> build_state(state[code], state, operation)
      |> Map.pop("total_price")

    total_price = Enum.reduce(state, 0, fn {_key, product}, acc -> product.total_price + acc end)

    Map.put(state, "total_price", Float.round(total_price, 2))
  end

  defp build_state(_new_prod, nil, state, :-), do: state
  defp build_state(_new_prod, %{count: 1} = product, state, :-), do: Map.delete(state, product.code)
  defp build_state(new_prod, product, state, operation) do
    product =
      new_prod
      |> build_item(product, operation)
      |> build_item_price()

    Map.put(state, product.code, product)
  end

  defp build_item(new_prod, product, operation) do
    %{
      price: new_prod.price,
      count: apply(Kernel, operation, [product[:count] || 0, 1]),
      discount_id: new_prod.discount_id,
      total_price: 0,
      code: new_prod.code
    }
  end

  defp build_item_price(%{count: count, price: price} = product) do
    discount = Map.get(discounts(), to_string(product.discount_id))

    total_price = cal({count, price}, discount)
    Map.put(product, :total_price, total_price)
  end

  # Dynamically calculate price for discount type of "BAGM" with buy & get
  defp cal({count, price}, %{type: "BAGM", buy: buy, get: get}) do
    count = if count == 1, do: count + 1, else: count
    x = count / (buy + get)
    y = trunc(x * get)
    count = count - y
    count * price
  end

  # Dynamically calculate price for discount type of percentage
  defp cal({count, price}, %{after_items: after_items, percentage: percentage}) do
    price_per_item = if count >= after_items, do:  price - (percentage * price)/100, else: price

    price_per_item * count
  end
end
