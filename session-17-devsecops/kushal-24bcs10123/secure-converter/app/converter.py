"""Pure conversion logic. No framework code here so it is trivial to unit test."""

# every unit is expressed as a factor to a base unit (metre, gram)
LENGTH = {"mm": 0.001, "cm": 0.01, "m": 1.0, "km": 1000.0, "in": 0.0254, "ft": 0.3048, "mi": 1609.344}
WEIGHT = {"mg": 0.001, "g": 1.0, "kg": 1000.0, "lb": 453.59237, "oz": 28.349523125}
TEMPERATURE = ("c", "f", "k")


class UnknownUnit(ValueError):
    pass


def convert_linear(value: float, src: str, dst: str, table: dict) -> float:
    src, dst = src.lower(), dst.lower()
    if src not in table or dst not in table:
        raise UnknownUnit(f"unknown unit: {src if src not in table else dst}")
    return value * table[src] / table[dst]


def convert_temperature(value: float, src: str, dst: str) -> float:
    src, dst = src.lower(), dst.lower()
    if src not in TEMPERATURE or dst not in TEMPERATURE:
        raise UnknownUnit(f"unknown unit: {src if src not in TEMPERATURE else dst}")
    # go through celsius
    celsius = {"c": value, "f": (value - 32) * 5 / 9, "k": value - 273.15}[src]
    return {"c": celsius, "f": celsius * 9 / 5 + 32, "k": celsius + 273.15}[dst]


def convert(category: str, value: float, src: str, dst: str) -> float:
    if category == "length":
        return convert_linear(value, src, dst, LENGTH)
    if category == "weight":
        return convert_linear(value, src, dst, WEIGHT)
    if category == "temperature":
        return convert_temperature(value, src, dst)
    raise UnknownUnit(f"unknown category: {category}")


def units() -> dict:
    return {"length": sorted(LENGTH), "weight": sorted(WEIGHT), "temperature": list(TEMPERATURE)}
