defprotocol GGity.Element do
  @moduledoc false

  @spec to_css(GGity.Element.t(), binary()) :: GGity.Element.t()
  def to_css(element, class)

  # @spec attributes_for(Element.t()) :: list()
  # def attributes_for(element)
end

defimpl GGity.Element, for: Atom do
  def to_css(nil, _class), do: ""
end

defimpl GGity.Element, for: Integer do
  def to_css(_element, _class), do: ""
end

defimpl GGity.Element, for: Any do
  def to_css(%element_type{} = element, class) do
    # [".", class, " {", GGity.Element.attributes_for(element), "}"]
    [".", class, " {", apply(element_type, :attributes_for, [element]), "}"]
    |> IO.chardata_to_string()
  end
end

# defimpl GGity.Element, for: Any do
#   def attributes_for(%element_type{} = element) do
#     element
#     |> Map.from_struct()
#     |> Enum.map(fn attribute -> apply(element_type, :attribute_for, attribute) end)
#   end
# end
