int main() {
  int f;
  char c;
  f = fopen("tests/six-cc-tests/empty.txt", 0);
  while ((c = fgetc(f)) != -1) {
    putchar(c);
  }
}
