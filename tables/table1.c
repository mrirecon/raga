
#include <stdio.h>

#define M_PI 3.14159265359

void fib(int N, int I, long G[I])
{
	G[0] = 1;
	G[1] = N;

	for (int i = 2; i < I; i++)
		G[i] = G[i - 1] + G[i - 2];
}

int main()
{
	int I = 14;
	long G[7 + 2][I];

	float br = 200;
	
	for (int N = 1; N <= 7; N++)
		fib(N, I, G[N]);

	for (int i = 1; i < I; i++) {

		// Fix definition: zero to one indexing in Fibonacci definition
		int i_update = i + 1;

		printf(" & \\multirow{2}{*}{%d} & \\cellcolor{gray!20} $\\psi_{%d}^N$ ", i_update, i_update);

		for (int N = 1; N <= 7; N += 1) {

			// Even spoke numbers have half the projection angles -> 1 / 2
			float n_proj_corr = 1. / ((0 == G[N][i] % 2) ? 2. : 1.);

			// Print bold if projections are larger than Nyquist limit
			if ((G[N][i] * n_proj_corr) > M_PI / 2. * br)
				printf("& \\cellcolor{gray!40} \\textbf{%11.3f}$^\\circ$ ", 180. * ((double)G[1][i - 1] / (double)G[N][i]));
			else
				printf("& \\cellcolor{gray!20} %11.3f$^\\circ$ ", 180. * ((double)G[1][i - 1] / (double)G[N][i]));
		}

		printf("\\\\\n & & {\\color{gray!70}$G_{%d}^1 / G_{%d}^N $} ", i_update - 1, i_update);

		for (int N = 1; N <= 7; N += 1)
			printf("&  {\\color{gray!70}%4ld / %4ld} ", G[1][i - 1], G[N][i]);

		if (I - 1 == i)
			printf("\\\\\n");
		else
			printf("\\\\\\cline{2-10}\n");
	}
}
