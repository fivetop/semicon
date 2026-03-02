#include <stdio.h>

int factorial(int n);

int main() {
        int result = factorial(6);
}

int factorial(int n) {
        int ret = 0;
        if (n <= 1)
                ret = 1;
        else
                ret = n*factorial(n-1);
        return ret;
}
