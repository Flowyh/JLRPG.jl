full_function_pattern(fn) = r"function\s+" * fn * r"(?:[\S\s])*?end\n*"
function_definition(fn) = r"function\s+" * fn * r"\(.*\)"
const function_name = r"function\s+(?<name>\w+)\(.*\)"

SPECIAL_FUNCTION_START(fn) = r"# <<: " * fn * r" start :>>"
SPECIAL_FUNCTION_END(fn) = r"# <<: " * fn * r" end :>>"
SPECIAL_FUNCTION_OVERLOAD_MSG(fn) = "# <<: $fn start :>>\n" *
                                    "# <<: OVERLOADED :>>\n" *
                                    "# <<: $fn end :>>"