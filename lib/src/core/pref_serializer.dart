abstract class PrefSerializer<T> {
  const PrefSerializer();

  String encode(T value);

  T decode(String value);
}
