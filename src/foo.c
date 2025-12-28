#include <stdio.h>

int mul(int a, int b) {
    return a * 10 + b;
}

int add(int a, int b) {
    return a + b;
}

void hello(const char* name) {
    printf("Hey %s!\n", name);
}