defprotocol GGity.Element do
  @moduledoc false

  @spec to_css(GGity.Element.t(), binary()) :: iolist()
  def to_css(element, class)
end

defimpl GGity.Element, for: Atom do
  def to_css(nil, _class), do: []
end

defimpl GGity.Element, for: Integer do
  def to_css(_element, _class), do: []
end

defimpl GGity.Element, for: Any do
  def to_css(%element_type{} = element, class) do
    [".", class, " {", apply(element_type, :attributes_for, [element]), "}"]
  end
end
