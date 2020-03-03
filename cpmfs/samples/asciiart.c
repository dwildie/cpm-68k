#include <stdio.h>

int main()
{
	int x, y, i;
	float ca, cb, a, b, t;
	char ch;

	for (y = -12; y < 13; y++) {
		for (x = -39; x < 40; x++) { 
			ca = x*0.0458;
			cb = y*0.08333;
			a = ca;
			b = cb;
			i = 0;
			ch = ' ';
			while (i < 16) { 
				t = a*a-b*b+ca;
				b = 2*a*b+cb;
				a = t;
				if (a*a + b*b > 4.0) { 
					if (i > 9) i += 7;
					ch = (char)(48+i);
					break;
				}
				i++;
			}
			printf("%c", ch);
		}
		printf("\n");
	}
}

