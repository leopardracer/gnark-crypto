// Code generated by gnark-crypto/generator. DO NOT EDIT.
#include "textflag.h"
#include "funcdata.h"
#include "go_asm.h"

// butterfly(a, b *Element)
// a, b = a+b, a-b
TEXT ·Butterfly(SB), NOFRAME|NOSPLIT, $0-16
	LDP  x+0(FP), (R16, R17)
	LDP  0(R16), (R0, R1)
	LDP  16(R16), (R2, R3)
	LDP  0(R17), (R4, R5)
	LDP  16(R17), (R6, R7)
	ADDS R0, R4, R8
	ADCS R1, R5, R9
	ADCS R2, R6, R10
	ADC  R3, R7, R11
	SUBS R4, R0, R4
	SBCS R5, R1, R5
	SBCS R6, R2, R6
	SBCS R7, R3, R7
	LDP  ·qElement+0(SB), (R0, R1)
	CSEL CS, ZR, R0, R12
	CSEL CS, ZR, R1, R13
	LDP  ·qElement+16(SB), (R2, R3)
	CSEL CS, ZR, R2, R14
	CSEL CS, ZR, R3, R15

	// add q if underflow, 0 if not
	ADDS R4, R12, R4
	ADCS R5, R13, R5
	STP  (R4, R5), 0(R17)
	ADCS R6, R14, R6
	ADC  R7, R15, R7
	STP  (R6, R7), 16(R17)

	// q = t - q
	SUBS R0, R8, R0
	SBCS R1, R9, R1
	SBCS R2, R10, R2
	SBCS R3, R11, R3

	// if no borrow, return q, else return t
	CSEL CS, R0, R8, R8
	CSEL CS, R1, R9, R9
	STP  (R8, R9), 0(R16)
	CSEL CS, R2, R10, R10
	CSEL CS, R3, R11, R11
	STP  (R10, R11), 16(R16)
	RET

// mul(res, x, y *Element)
// Algorithm 2 of Faster Montgomery Multiplication and Multi-Scalar-Multiplication for SNARKS
// by Y. El Housni and G. Botrel https://doi.org/10.46586/tches.v2023.i3.504-521
TEXT ·mul(SB), NOFRAME|NOSPLIT, $0-24
#define DIVSHIFT() \
	MUL   R7, R17, R0  \
	ADDS  R0, R11, R11 \
	MUL   R8, R17, R0  \
	ADCS  R0, R12, R12 \
	MUL   R9, R17, R0  \
	ADCS  R0, R13, R13 \
	MUL   R10, R17, R0 \
	ADCS  R0, R14, R14 \
	ADC   R15, ZR, R15 \
	UMULH R7, R17, R0  \
	ADDS  R0, R12, R11 \
	UMULH R8, R17, R0  \
	ADCS  R0, R13, R12 \
	UMULH R9, R17, R0  \
	ADCS  R0, R14, R13 \
	UMULH R10, R17, R0 \
	ADCS  R0, R15, R14 \

#define MUL_WORD_N() \
	MUL   R3, R2, R0    \
	ADDS  R0, R11, R11  \
	MUL   R11, R16, R17 \
	MUL   R4, R2, R0    \
	ADCS  R0, R12, R12  \
	MUL   R5, R2, R0    \
	ADCS  R0, R13, R13  \
	MUL   R6, R2, R0    \
	ADCS  R0, R14, R14  \
	ADC   ZR, ZR, R15   \
	UMULH R3, R2, R0    \
	ADDS  R0, R12, R12  \
	UMULH R4, R2, R0    \
	ADCS  R0, R13, R13  \
	UMULH R5, R2, R0    \
	ADCS  R0, R14, R14  \
	UMULH R6, R2, R0    \
	ADC   R0, R15, R15  \
	DIVSHIFT()          \

#define MUL_WORD_0() \
	MUL   R3, R2, R11   \
	MUL   R4, R2, R12   \
	MUL   R5, R2, R13   \
	MUL   R6, R2, R14   \
	UMULH R3, R2, R0    \
	ADDS  R0, R12, R12  \
	UMULH R4, R2, R0    \
	ADCS  R0, R13, R13  \
	UMULH R5, R2, R0    \
	ADCS  R0, R14, R14  \
	UMULH R6, R2, R0    \
	ADC   R0, ZR, R15   \
	MUL   R11, R16, R17 \
	DIVSHIFT()          \

	MOVD y+16(FP), R1
	MOVD x+8(FP), R0
	LDP  0(R0), (R3, R4)
	LDP  16(R0), (R5, R6)
	MOVD 0(R1), R2
	MOVD $const_qInvNeg, R16
	LDP  ·qElement+0(SB), (R7, R8)
	LDP  ·qElement+16(SB), (R9, R10)
	MUL_WORD_0()
	MOVD 8(R1), R2
	MUL_WORD_N()
	MOVD 16(R1), R2
	MUL_WORD_N()
	MOVD 24(R1), R2
	MUL_WORD_N()

	// reduce if necessary
	SUBS R7, R11, R7
	SBCS R8, R12, R8
	SBCS R9, R13, R9
	SBCS R10, R14, R10
	MOVD res+0(FP), R0
	CSEL CS, R7, R11, R11
	CSEL CS, R8, R12, R12
	STP  (R11, R12), 0(R0)
	CSEL CS, R9, R13, R13
	CSEL CS, R10, R14, R14
	STP  (R13, R14), 16(R0)
	RET

// reduce(res *Element)
TEXT ·reduce(SB), NOFRAME|NOSPLIT, $0-8
	LDP  ·qElement+0(SB), (R4, R5)
	LDP  ·qElement+16(SB), (R6, R7)
	MOVD res+0(FP), R8
	LDP  0(R8), (R0, R1)
	LDP  16(R8), (R2, R3)

	// q = t - q
	SUBS R4, R0, R4
	SBCS R5, R1, R5
	SBCS R6, R2, R6
	SBCS R7, R3, R7

	// if no borrow, return q, else return t
	CSEL CS, R4, R0, R0
	CSEL CS, R5, R1, R1
	STP  (R0, R1), 0(R8)
	CSEL CS, R6, R2, R2
	CSEL CS, R7, R3, R3
	STP  (R2, R3), 16(R8)
	RET
