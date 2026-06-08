from math import isfinite


class QueryParameterError(ValueError):
    pass


def required_finite_float(params, name):
    raw_value = params.get(name)

    if raw_value in (None, ""):
        raise QueryParameterError(f"Missing required query parameter: {name}")

    try:
        value = float(raw_value)
    except (TypeError, ValueError):
        raise QueryParameterError(
            f"Invalid query parameter: {name} must be a number"
        ) from None

    if not isfinite(value):
        raise QueryParameterError(
            f"Invalid query parameter: {name} must be a finite number"
        )

    return value
