extension AsyncFold<T, C> on Iterable<T> {
  Future<C> foldAsync<C>(C initialValue, Future<C> Function(C, T) predicate) async {
    var cur = initialValue;
    for(var item in this) {
      cur = await predicate(cur, item);
    }
    return cur;
  }
}