
#include <stdio.h>
#include <math.h>

float tga(int n)
{
	return M_PI / ((sqrtf(5.) + 1.) / 2. + (float)n - 1.);
}

int main()
{

	int N = 7;

	printf("\\multicolumn{%d}{l}{Golden Ratio Angles [$^{\\circ}$]} \\vspace*{0.1cm} \\\\\n", N);

	for (int n = 1; n <= N; n++)
		(N > n) ? printf("$\\psi^{%d}$ & ", n) : printf("$\\psi^{%d}$ \\\\\\hline \n", n);

	for (int n = 1; n <= N; n++)
		(N > n) ?  printf("%11.3f & ", 180. / M_PI * tga(n)) : printf("%11.3f \\vspace*{0.5cm}\\\\ \n ", 180. / M_PI * tga(n));

	printf("\\multicolumn{%d}{l}{Doubled Golden Ratio Angles [$^{\\circ}$]} \\vspace*{0.1cm} \\\\\n", N);

	for (int n = 1; n <= N; n++)
		(N > n) ? printf("$2\\psi^{%d}$ & ", n) : printf("$2\\psi^{%d}$ \\\\\\hline \n", n);

	for (int n = 1; n <= N; n++) {

		if (N > n)
			printf("%11.3f & ", 2. * 180. / M_PI * tga(n));
		else
			printf("%11.3f \\vspace*{0.2cm} \\\\\n", 2. * 180. / M_PI * tga(n));
	}

	for (int n = N + 1; n <= 2 * N; n++)
		(2 * N > n) ? printf("$2\\psi^{%d}$ & ", n) : printf("$2\\psi^{%d}$ \\\\\\hline \n", n);

	for (int n = N + 1; n <= 2 * N; n++)
		(2 * N > n) ?  printf("%11.3f & ", 2. * 180. / M_PI * tga(n)) : printf("%11.3f \\\\\n", 2. * 180. / M_PI * tga(n));
}

