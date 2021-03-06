import semmle.code.cpp.models.interfaces.ArrayFunction
import semmle.code.cpp.models.interfaces.Taint
import semmle.code.cpp.models.interfaces.Alias
import semmle.code.cpp.models.interfaces.SideEffect

/** Pure string functions. */
private class PureStrFunction extends AliasFunction, ArrayFunction, TaintFunction,
  SideEffectFunction {
  PureStrFunction() {
    hasGlobalOrStdName([
        atoi(), "strcasestr", "strchnul", "strchr", "strchrnul", "strstr", "strpbrk", "strrchr",
        "strspn", strtol(), strrev(), strcmp(), strlwr(), strupr()
      ])
  }

  override predicate hasArrayInput(int bufParam) {
    getParameter(bufParam).getUnspecifiedType() instanceof PointerType
  }

  override predicate hasArrayWithNullTerminator(int bufParam) {
    getParameter(bufParam).getUnspecifiedType() instanceof PointerType
  }

  override predicate hasTaintFlow(FunctionInput input, FunctionOutput output) {
    exists(ParameterIndex i |
      (
        input.isParameter(i) and
        exists(getParameter(i))
        or
        input.isParameterDeref(i) and
        getParameter(i).getUnspecifiedType() instanceof PointerType
      ) and
      // Functions that end with _l also take a locale argument (always as the last argument),
      // and we don't want taint from those arguments.
      (not this.getName().matches("%\\_l") or exists(getParameter(i + 1)))
    ) and
    (
      output.isReturnValueDeref() and
      getUnspecifiedType() instanceof PointerType
      or
      output.isReturnValue()
    )
  }

  override predicate parameterNeverEscapes(int i) {
    getParameter(i).getUnspecifiedType() instanceof PointerType and
    not parameterEscapesOnlyViaReturn(i)
  }

  override predicate parameterEscapesOnlyViaReturn(int i) {
    i = 0 and
    getUnspecifiedType() instanceof PointerType
  }

  override predicate parameterIsAlwaysReturned(int i) { none() }

  override predicate hasOnlySpecificReadSideEffects() { any() }

  override predicate hasOnlySpecificWriteSideEffects() { any() }

  override predicate hasSpecificReadSideEffect(ParameterIndex i, boolean buffer) {
    getParameter(i).getUnspecifiedType() instanceof PointerType and
    buffer = true
  }
}

private string atoi() { result = ["atof", "atoi", "atol", "atoll"] }

private string strtol() { result = ["strtod", "strtof", "strtol", "strtoll", "strtoq", "strtoul"] }

private string strlwr() {
  result = ["_strlwr", "_wcslwr", "_mbslwr", "_strlwr_l", "_wcslwr_l", "_mbslwr_l"]
}

private string strupr() {
  result = ["_strupr", "_wcsupr", "_mbsupr", "_strupr_l", "_wcsupr_l", "_mbsupr_l"]
}

private string strrev() { result = ["_strrev", "_wcsrev", "_mbsrev", "_mbsrev_l"] }

private string strcmp() {
  // NOTE: `strcoll` doesn't satisfy _all_ the definitions of purity: its behavior depends on
  // `LC_COLLATE` (which is set by `setlocale`). Not sure this behavior worth including in the model, so
  // for now we interpret the function as being pure.
  result =
    [
      "strcmp", "strcspn", "strncmp", "strcoll", "strverscmp", "_mbsnbcmp", "_mbsnbcmp_l",
      "_stricmp"
    ]
}

/** String standard `strlen` function, and related functions for computing string lengths. */
private class StrLenFunction extends AliasFunction, ArrayFunction, SideEffectFunction {
  StrLenFunction() {
    hasGlobalOrStdName(["strlen", "strnlen", "wcslen"])
    or
    hasGlobalName(["_mbslen", "_mbslen_l", "_mbstrlen", "_mbstrlen_l"])
  }

  override predicate hasArrayInput(int bufParam) {
    getParameter(bufParam).getUnspecifiedType() instanceof PointerType
  }

  override predicate hasArrayWithNullTerminator(int bufParam) {
    getParameter(bufParam).getUnspecifiedType() instanceof PointerType
  }

  override predicate parameterNeverEscapes(int i) {
    getParameter(i).getUnspecifiedType() instanceof PointerType
  }

  override predicate parameterEscapesOnlyViaReturn(int i) { none() }

  override predicate parameterIsAlwaysReturned(int i) { none() }

  override predicate hasOnlySpecificReadSideEffects() { any() }

  override predicate hasOnlySpecificWriteSideEffects() { any() }

  override predicate hasSpecificReadSideEffect(ParameterIndex i, boolean buffer) {
    getParameter(i).getUnspecifiedType() instanceof PointerType and
    buffer = true
  }
}

/** Pure functions. */
private class PureFunction extends TaintFunction, SideEffectFunction {
  PureFunction() { hasGlobalOrStdName(["abs", "labs"]) }

  override predicate hasTaintFlow(FunctionInput input, FunctionOutput output) {
    exists(ParameterIndex i |
      input.isParameter(i) and
      exists(getParameter(i))
    ) and
    output.isReturnValue()
  }

  override predicate hasOnlySpecificReadSideEffects() { any() }

  override predicate hasOnlySpecificWriteSideEffects() { any() }
}

/** Pure raw-memory functions. */
private class PureMemFunction extends AliasFunction, ArrayFunction, TaintFunction,
  SideEffectFunction {
  PureMemFunction() {
    hasGlobalOrStdName([
        "memchr", "__builtin_memchr", "memrchr", "rawmemchr", "memcmp", "__builtin_memcmp", "memmem"
      ]) or
    this.hasGlobalName("memfrob")
  }

  override predicate hasArrayInput(int bufParam) {
    getParameter(bufParam).getUnspecifiedType() instanceof PointerType
  }

  override predicate hasTaintFlow(FunctionInput input, FunctionOutput output) {
    exists(ParameterIndex i |
      (
        input.isParameter(i) and
        exists(getParameter(i))
        or
        input.isParameterDeref(i) and
        getParameter(i).getUnspecifiedType() instanceof PointerType
      ) and
      // `memfrob` should not have taint from the size argument.
      (not this.hasGlobalName("memfrob") or i = 0)
    ) and
    (
      output.isReturnValueDeref() and
      getUnspecifiedType() instanceof PointerType
      or
      output.isReturnValue()
    )
  }

  override predicate parameterNeverEscapes(int i) {
    getParameter(i).getUnspecifiedType() instanceof PointerType and
    not parameterEscapesOnlyViaReturn(i)
  }

  override predicate parameterEscapesOnlyViaReturn(int i) {
    i = 0 and
    getUnspecifiedType() instanceof PointerType
  }

  override predicate parameterIsAlwaysReturned(int i) { none() }

  override predicate hasOnlySpecificReadSideEffects() { any() }

  override predicate hasOnlySpecificWriteSideEffects() { any() }

  override predicate hasSpecificReadSideEffect(ParameterIndex i, boolean buffer) {
    getParameter(i).getUnspecifiedType() instanceof PointerType and
    buffer = true
  }
}
