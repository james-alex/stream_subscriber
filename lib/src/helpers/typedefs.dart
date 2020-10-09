typedef OnEvent<E> = void Function(E event);

typedef OnUpdate<T> = void Function(T value);

typedef OnChange<E> = void Function(E event);

typedef Test<E> = bool Function(E element);
