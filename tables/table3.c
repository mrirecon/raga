
#include <stdio.h>
#include <math.h>
#include <float.h>

// gcc table3.c -lm && ./a.out

void fib(int N, int I, long G[I])
{
	G[0] = 1;
	G[1] = N;

	for (int i = 2; i < I; i++)
		G[i] = G[i - 1] + G[i - 2];
}

int main()
{
	int tiny_gold = 1;

	long double gr_l = (sqrtl(5.) + 1.) / 2.;
	long double ga_l = (long double)M_PI / (gr_l + (long double)tiny_gold - 1.);
	
	double gr_d = (sqrt(5.) + 1.) / 2.;
	double ga_d = (double)M_PI / (gr_d + (double)tiny_gold - 1.);

	float gr_f = (sqrtf(5.f) + 1.f) / 2.f;
	float ga_f = (float)M_PI / (gr_f + (float)tiny_gold - 1.f);

	// RAGA

	int I = 14;
	long G[7 + 2][I];

	for (int N = 1; N <= 7; N++)
		fib(N, I, G[N]);

	int index = 1;	
	int approx = 13 - 1;
	float raga_base_f = ((float)M_PI / G[index][approx]);
	double raga_base_d = ((double)M_PI / G[index][approx]);
	long double raga_base_l = ((long double)M_PI / G[index][approx]);
#if 0
	printf("RAGA %f %ld\n", G[1][approx - 1] * raga_base_d * 180. / M_PI, G[index][approx]);
	printf("GA %f\n", ga_d * 180.f / M_PI);
#endif
	// Analyzed repetitions

	enum { N = 5};

	//int pos[N] = { 1, 4, 12, 26, 50};
	int pos[N] = { 10000., 25000, 100000, 250000, 500000};

	// Data storage
	long double data[N][10] = { 0 }; // 6 methods to calculate

	// Perform calculations of angles

	long double angle_l = 0.;
	double angle_d = 0.;
	float angle_f = 0.f;

	long double angle2_l = 0.;
	double angle2_d = 0.;
	float angle2_f = 0.f;

	long double scale = 180. / (long double)M_PI;

	for (int i = 0; i < 1000000; i++) {

		long double c_mod_l = fmodl(ga_l * (long double)i, 2. * (long double)M_PI);
		double c_mod_d = fmod(ga_d * (double)i, 2. * (double)M_PI);
		float c_mod_f = fmodf(ga_f * (float)i, 2.f * (float)M_PI);

		long double s_mod_l = fmod(angle_l, 2. * (long double)M_PI);
		double s_mod_d = fmod(angle_d, 2. * (double)M_PI);
		float s_mod_f = fmodf(angle_f, 2.f * (float)M_PI);

		for (int ind = 0; ind < N; ind++) {
			if (pos[ind] == i) {


				data[ind][0] = c_mod_d  * scale;
				data[ind][1] = c_mod_f  * scale;
				data[ind][2] = s_mod_d * scale;
				data[ind][3] = s_mod_f * scale;
				data[ind][4] = angle2_d * scale;
				data[ind][5] = angle2_f * scale; 

				data[ind][8] = angle2_l * scale;
			}
		}

		angle2_l = fmodl(angle2_l + ga_l, 2. * (long double)M_PI);
		angle2_d = fmod(angle2_d + ga_d, 2. * (double)M_PI);
		angle2_f = fmodf(angle2_f + ga_f, 2.f * (float)M_PI);

		angle_l += ga_l;
		angle_d += ga_d;
		angle_f += ga_f;
	}

	for (int ind = 0; ind < N; ind++) {

		data[ind][6] = (((pos[ind] * G[1][approx - 1]) % G[index][approx]) * raga_base_d) * scale;
		data[ind][7] = (((pos[ind] * G[1][approx - 1]) % G[index][approx]) * raga_base_f) * scale;
		data[ind][9] = (((pos[ind] * G[1][approx - 1]) % G[index][approx]) * raga_base_l) * scale;
	}


	// Create Output of Latex Table

	// printf(" & \\multirow{6}{*}{Angles [$^{\\circ}$]}\\\\\\hline\n");
	// printf("Rep & double$_{(\\cdot)}$ & single$_{(\\cdot)}$ & double$_{(+)}$ & single$_{(+)}$ & double$_{(+,\\text{mod})}$ & single$_{(+,\\text{mod})}$\\\\\\hline\n");

	// Repetition Header line
	printf("\\begin{tabular}{cl||c|c|c|c|c}\n");
	printf("\\multicolumn{7}{c}{\\hspace{2cm}\\textbf{Repetitions}}\\\\\n");
	printf("&");
	for (int ind = 0; ind < N; ind++)
		printf(" & %d", pos[ind]);
	printf("\\\\\\cmidrule{2-7}\\morecmidrules\\cmidrule{2-7}\n");

	// Methods

	printf(" & {\\cellcolor{gray!40}\\ \\textbf{GA Ref} [$^{\\circ}$]}");
	for (int ind = 0; ind < N; ind++)
		printf(" & {\\cellcolor{gray!40}%.2Lf}", data[ind][8]);
	printf("\\\\\\cmidrule{2-7}\n");
	//printf("\\\\\\cmidrule{2-7}\\morecmidrules\\cmidrule{2-7}\n");


	// RAGA
	//
	printf("& {\\cellcolor{gray!40}\\  \\ \\textbf{RAGA Ref} [$^{\\circ}$]}");
	for (int ind = 0; ind < N; ind++)
		printf(" & {\\cellcolor{gray!40}%.2Lf}", data[ind][9]);
	printf("\\\\\\cmidrule{2-7}\\morecmidrules\\cmidrule{2-7}\n");


	// -----------------------------------
	// 		SINGLE
	// -----------------------------------

	printf("\\multirow{3}{*}{\\rotatebox[origin=c]{90}{\\textbf{Golden Ratio}}} ");

	printf("& {\\cellcolor{gray!40}\\textbf{single}$_{(\\cdot)}$ [$^{\\circ}$]}");
#if 0
	for (int ind = 0; ind < N; ind++)
		printf(" & {\\cellcolor{gray!40}%.3Lf}", data[ind][1]);
	printf("\\\\\n");

	printf("&{\\color{gray!70}\\footnotesize(Diff. to Ref.) [$^{\\circ}$]}");
#endif
	for (int ind = 0; ind < N; ind++)
		printf("&{\\color{gray!70}%.1Le}", data[ind][8] - data[ind][1]);
	printf("\\\\\\cmidrule{2-7}\n");


	printf("& {\\cellcolor{gray!40}\\textbf{single}$_{(+)}$ [$^{\\circ}$]}");
#if 0
	for (int ind = 0; ind < N; ind++)
		printf(" & {\\cellcolor{gray!40}%.3Lf}", data[ind][3]);
	printf("\\\\\n");

	printf("&{\\color{gray!70}\\footnotesize(Diff. to Ref.) [$^{\\circ}$]}");
#endif
	for (int ind = 0; ind < N; ind++)
		printf("&{\\color{gray!70}%.1Le}", data[ind][8] - data[ind][3]);
	printf("\\\\\\cmidrule{2-7}\n");



	printf("& {\\cellcolor{gray!40}\\textbf{single}$_{(+,\\text{mod})}$ [$^{\\circ}$]}");
#if 0
	for (int ind = 0; ind < N; ind++)
		printf(" & {\\cellcolor{gray!40}%.3Lf}", data[ind][5]);
	printf("\\\\\n");

	printf("&{\\color{gray!70}\\footnotesize(Diff. to Ref.) [$^{\\circ}$]}");
#endif
	for (int ind = 0; ind < N; ind++)
		printf("&{\\color{gray!70}%.1Le}", data[ind][8] - data[ind][5]);
	printf("\\\\\\cmidrule{2-7}\\morecmidrules\\cmidrule{2-7}\n");


	// RAGA
	//
	printf("& {\\cellcolor{gray!40}\\textbf{single}$_{\\text{RAGA}}$ [$^{\\circ}$]}");
#if 0
	for (int ind = 0; ind < N; ind++)
		printf(" & {\\cellcolor{gray!40}%.3Lf}", data[ind][7]);
	printf("\\\\\n");

	printf("&{\\color{gray!70}\\footnotesize(Diff. to Ref.) [$^{\\circ}$]}");
#endif
	for (int ind = 0; ind < N; ind++)
		printf("&{\\cellcolor{gray!10}\\color{gray!70}%.1Le}", data[ind][9] - data[ind][7]);
	printf("\\\\\\cmidrule{2-7}\\morecmidrules\\cmidrule{2-7}\n");

	// -----------------------------------
	// 		DOUBLE
	// -----------------------------------

	printf("\\multirow{3}{*}{\\rotatebox[origin=c]{90}{\\textbf{Golden Ratio}}} ");

	printf("& {\\cellcolor{gray!40}\\textbf{double}$_{(\\cdot)}$ [$^{\\circ}$]}");
#if 0
	for (int ind = 0; ind < N; ind++)
		printf(" & {\\cellcolor{gray!40}%.3Lf}", data[ind][0]);
	printf("\\\\\n");

	printf("&{\\color{gray!70}\\footnotesize(Diff. to Ref.) [$^{\\circ}$]}");
#endif
	for (int ind = 0; ind < N; ind++)
		if (data[ind][8] == data[ind][0])
			printf("&{\\color{gray!70}0}");
		else	
			printf("&{\\color{gray!70}%.1Le}", data[ind][8] - data[ind][0]);
	printf("\\\\\\cmidrule{2-7}\n");



	printf("& {\\cellcolor{gray!40}\\textbf{double}$_{(+)}$ [$^{\\circ}$]}");
#if 0
	for (int ind = 0; ind < N; ind++)
		printf(" & {\\cellcolor{gray!40}%.3Lf}", data[ind][2]);
	printf("\\\\\n");

	printf("&{\\color{gray!70}\\footnotesize(Diff. to Ref.) [$^{\\circ}$]}");
#endif
	for (int ind = 0; ind < N; ind++)
		printf("&{\\color{gray!70}%.1Le}", data[ind][8] - data[ind][2]);
	printf("\\\\\\cmidrule{2-7}\n");



	printf("& {\\cellcolor{gray!40}\\textbf{double}$_{(+,\\text{mod})}$ [$^{\\circ}$]}");
#if 0
	for (int ind = 0; ind < N; ind++)
		printf(" & {\\cellcolor{gray!40}%.3Lf}", data[ind][4]);
	printf("\\\\\n");

	printf("&{\\color{gray!70}\\footnotesize(Diff. to Ref.) [$^{\\circ}$]}");
#endif
	for (int ind = 0; ind < N; ind++)
		printf("&{\\color{gray!70}%.1Le}", data[ind][8] - data[ind][4]);
	printf("\\\\\\cmidrule{2-7}\n");


	// RAGA
	//
	printf("& {\\cellcolor{gray!40}\\textbf{double}$_{\\text{RAGA}}$ [$^{\\circ}$]}");
#if 0
	for (int ind = 0; ind < N; ind++)
		printf(" & {\\cellcolor{gray!40}%.3Lf}", data[ind][6]);
	printf("\\\\\n");

	printf("&{\\color{gray!70}\\footnotesize(Diff. to Ref.) [$^{\\circ}$]}");
#endif
	for (int ind = 0; ind < N; ind++)
		if (data[ind][9] == data[ind][6])
			printf("&{\\color{gray!70}0}");
		else
			printf("&{\\cellcolor{gray!10}\\color{gray!70}%.1Le}", data[ind][9] - data[ind][6]);
	printf("\\\\\\cmidrule{2-7}\\morecmidrules\\cmidrule{2-7}\n");

	// Add Acquisition time

	double tr = 0.002;

	printf("& Acquisition [min:s]");
	for (int ind = 0; ind < N; ind++)
		printf("&%d:%02d", (int)floor((double)pos[ind] * tr / 60. ), (int)fmod((double)pos[ind] * tr, 60) );
	printf("\\\\\\cmidrule{2-7}\n");

	printf("\\end{tabular}\n");

	// for (int ind = 0; ind < N; ind++)
	// 	printf("%d & %.11f & %.11f & %.11f & %.11f & %.11f & %.11f\\\\\\hline\n", pos[ind], data[ind][0], data[ind][1], data[ind][2], data[ind][3], data[ind][4], data[ind][5]);
	//
	//

//	printf("eps [°] %Le %Le %Le\n", FLT_EPSILON * scale, DBL_EPSILON * scale, LDBL_EPSILON *scale);
}
