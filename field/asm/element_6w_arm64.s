// Code generated by gnark-crypto/generator. DO NOT EDIT.
#include "textflag.h"
#include "funcdata.h"
#include "go_asm.h"

// add(res, x, y *Element)
TEXT ·add(SB), NOSPLIT, $0-24
	LDP  x+8(FP), (R19, R20)
	LDP  0(R19), (R12, R13)
	LDP  16(R19), (R14, R15)
	LDP  32(R19), (R16, R17)
	LDP  0(R20), (R6, R7)
	LDP  16(R20), (R8, R9)
	LDP  32(R20), (R10, R11)
	ADDS R12, R6, R6
	ADCS R13, R7, R7
	ADCS R14, R8, R8
	ADCS R15, R9, R9
	ADCS R16, R10, R10
	ADCS R17, R11, R11

	// load modulus and subtract
	LDP  ·qElement+0(SB), (R0, R1)
	LDP  ·qElement+16(SB), (R2, R3)
	LDP  ·qElement+32(SB), (R4, R5)
	SUBS R0, R6, R0
	SBCS R1, R7, R1
	SBCS R2, R8, R2
	SBCS R3, R9, R3
	SBCS R4, R10, R4
	SBCS R5, R11, R5

	// reduce if necessary
	CSEL CS, R0, R6, R6
	CSEL CS, R1, R7, R7
	CSEL CS, R2, R8, R8
	CSEL CS, R3, R9, R9
	CSEL CS, R4, R10, R10
	CSEL CS, R5, R11, R11

	// store
	MOVD res+0(FP), R21
	STP  (R6, R7), 0(R21)
	STP  (R8, R9), 16(R21)
	STP  (R10, R11), 32(R21)
	RET

// double(res, x *Element)
TEXT ·double(SB), NOSPLIT, $0-16
	LDP  res+0(FP), (R1, R0)
	LDP  0(R0), (R2, R3)
	LDP  16(R0), (R4, R5)
	LDP  32(R0), (R6, R7)
	ADDS R2, R2, R2
	ADCS R3, R3, R3
	ADCS R4, R4, R4
	ADCS R5, R5, R5
	ADCS R6, R6, R6
	ADCS R7, R7, R7

	// load modulus and subtract
	LDP  ·qElement+0(SB), (R8, R9)
	LDP  ·qElement+16(SB), (R10, R11)
	LDP  ·qElement+32(SB), (R12, R13)
	SUBS R8, R2, R8
	SBCS R9, R3, R9
	SBCS R10, R4, R10
	SBCS R11, R5, R11
	SBCS R12, R6, R12
	SBCS R13, R7, R13

	// reduce if necessary
	CSEL CS, R8, R2, R2
	CSEL CS, R9, R3, R3
	CSEL CS, R10, R4, R4
	CSEL CS, R11, R5, R5
	CSEL CS, R12, R6, R6
	CSEL CS, R13, R7, R7
	STP  (R2, R3), 0(R1)
	STP  (R4, R5), 16(R1)
	STP  (R6, R7), 32(R1)
	RET

// sub(res, x, y *Element)
TEXT ·sub(SB), NOSPLIT, $0-24
	LDP  x+8(FP), (R19, R20)
	LDP  0(R19), (R6, R7)
	LDP  16(R19), (R8, R9)
	LDP  32(R19), (R10, R11)
	LDP  0(R20), (R0, R1)
	LDP  16(R20), (R2, R3)
	LDP  32(R20), (R4, R5)
	SUBS R0, R6, R0
	SBCS R1, R7, R1
	SBCS R2, R8, R2
	SBCS R3, R9, R3
	SBCS R4, R10, R4
	SBCS R5, R11, R5

	// load modulus and select
	LDP  ·qElement+0(SB), (R12, R13)
	LDP  ·qElement+16(SB), (R14, R15)
	LDP  ·qElement+32(SB), (R16, R17)
	CSEL CS, ZR, R12, R12
	CSEL CS, ZR, R13, R13
	CSEL CS, ZR, R14, R14
	CSEL CS, ZR, R15, R15
	CSEL CS, ZR, R16, R16
	CSEL CS, ZR, R17, R17

	// add q if underflow, 0 if not
	ADDS R0, R12, R0
	ADCS R1, R13, R1
	ADCS R2, R14, R2
	ADCS R3, R15, R3
	ADCS R4, R16, R4
	ADCS R5, R17, R5
	MOVD res+0(FP), R21
	STP  (R0, R1), 0(R21)
	STP  (R2, R3), 16(R21)
	STP  (R4, R5), 32(R21)
	RET

// butterfly(x, y *Element)
TEXT ·Butterfly(SB), NOSPLIT, $0-16
	LDP  x+0(FP), (R25, R26)
	LDP  0(R25), (R0, R1)
	LDP  16(R25), (R2, R3)
	LDP  32(R25), (R4, R5)
	LDP  0(R26), (R6, R7)
	LDP  16(R26), (R8, R9)
	LDP  32(R26), (R10, R11)
	ADDS R0, R6, R12
	ADCS R1, R7, R13
	ADCS R2, R8, R14
	ADCS R3, R9, R15
	ADCS R4, R10, R16
	ADCS R5, R11, R17

	// load modulus and subtract
	LDP  ·qElement+0(SB), (R19, R20)
	LDP  ·qElement+16(SB), (R21, R22)
	LDP  ·qElement+32(SB), (R23, R24)
	SUBS R19, R12, R19
	SBCS R20, R13, R20
	SBCS R21, R14, R21
	SBCS R22, R15, R22
	SBCS R23, R16, R23
	SBCS R24, R17, R24

	// reduce if necessary
	CSEL CS, R19, R12, R12
	CSEL CS, R20, R13, R13
	CSEL CS, R21, R14, R14
	CSEL CS, R22, R15, R15
	CSEL CS, R23, R16, R16
	CSEL CS, R24, R17, R17

	// store
	STP  (R12, R13), 0(R25)
	STP  (R14, R15), 16(R25)
	STP  (R16, R17), 32(R25)
	SUBS R6, R0, R6
	SBCS R7, R1, R7
	SBCS R8, R2, R8
	SBCS R9, R3, R9
	SBCS R10, R4, R10
	SBCS R11, R5, R11

	// load modulus and select
	LDP  ·qElement+0(SB), (R19, R20)
	LDP  ·qElement+16(SB), (R21, R22)
	LDP  ·qElement+32(SB), (R23, R24)
	CSEL CS, ZR, R19, R19
	CSEL CS, ZR, R20, R20
	CSEL CS, ZR, R21, R21
	CSEL CS, ZR, R22, R22
	CSEL CS, ZR, R23, R23
	CSEL CS, ZR, R24, R24

	// add q if underflow, 0 if not
	ADDS R6, R19, R6
	ADCS R7, R20, R7
	ADCS R8, R21, R8
	ADCS R9, R22, R9
	ADCS R10, R23, R10
	ADCS R11, R24, R11

	// store
	STP (R6, R7), 0(R26)
	STP (R8, R9), 16(R26)
	STP (R10, R11), 32(R26)
	RET

// mul(res, x, y *Element)
TEXT ·mul(SB), NOSPLIT, $0-24
	LDP x+8(FP), (R0, R1)
	LDP 0(R0), (R3, R4)
	LDP 16(R0), (R5, R6)
	LDP 32(R0), (R7, R8)
	LDP ·qElement+0(SB), (R16, R17)
	LDP ·qElement+16(SB), (R19, R20)
	LDP ·qElement+32(SB), (R21, R22)

#define DIVSHIFT() \
	MOVD  $const_qInvNeg, R2 \
	MUL   R9, R2, R2         \
	MUL   R16, R2, R0        \
	ADDS  R0, R9, R9         \
	MUL   R17, R2, R0        \
	ADCS  R0, R10, R10       \
	MUL   R19, R2, R0        \
	ADCS  R0, R11, R11       \
	MUL   R20, R2, R0        \
	ADCS  R0, R12, R12       \
	MUL   R21, R2, R0        \
	ADCS  R0, R13, R13       \
	MUL   R22, R2, R0        \
	ADCS  R0, R14, R14       \
	ADCS  ZR, R15, R15       \
	UMULH R16, R2, R0        \
	ADDS  R0, R10, R9        \
	UMULH R17, R2, R0        \
	ADCS  R0, R11, R10       \
	UMULH R19, R2, R0        \
	ADCS  R0, R12, R11       \
	UMULH R20, R2, R0        \
	ADCS  R0, R13, R12       \
	UMULH R21, R2, R0        \
	ADCS  R0, R14, R13       \
	UMULH R22, R2, R0        \
	ADCS  R0, R15, R14       \

#define MUL_WORD_N() \
	MUL   R3, R2, R0   \
	ADDS  R0, R9, R9   \
	MUL   R4, R2, R0   \
	ADCS  R0, R10, R10 \
	MUL   R5, R2, R0   \
	ADCS  R0, R11, R11 \
	MUL   R6, R2, R0   \
	ADCS  R0, R12, R12 \
	MUL   R7, R2, R0   \
	ADCS  R0, R13, R13 \
	MUL   R8, R2, R0   \
	ADCS  R0, R14, R14 \
	ADCS  ZR, ZR, R15  \
	UMULH R3, R2, R0   \
	ADDS  R0, R10, R10 \
	UMULH R4, R2, R0   \
	ADCS  R0, R11, R11 \
	UMULH R5, R2, R0   \
	ADCS  R0, R12, R12 \
	UMULH R6, R2, R0   \
	ADCS  R0, R13, R13 \
	UMULH R7, R2, R0   \
	ADCS  R0, R14, R14 \
	UMULH R8, R2, R0   \
	ADCS  R0, R15, R15 \
	DIVSHIFT()         \

#define MUL_WORD_0() \
	MUL   R3, R2, R9   \
	MUL   R4, R2, R10  \
	MUL   R5, R2, R11  \
	MUL   R6, R2, R12  \
	MUL   R7, R2, R13  \
	MUL   R8, R2, R14  \
	UMULH R3, R2, R0   \
	ADDS  R0, R10, R10 \
	UMULH R4, R2, R0   \
	ADCS  R0, R11, R11 \
	UMULH R5, R2, R0   \
	ADCS  R0, R12, R12 \
	UMULH R6, R2, R0   \
	ADCS  R0, R13, R13 \
	UMULH R7, R2, R0   \
	ADCS  R0, R14, R14 \
	UMULH R8, R2, R0   \
	ADCS  ZR, R0, R15  \
	DIVSHIFT()         \

	// mul body
	MOVD 0(R1), R2
	MUL_WORD_0()
	MOVD 8(R1), R2
	MUL_WORD_N()
	MOVD 16(R1), R2
	MUL_WORD_N()
	MOVD 24(R1), R2
	MUL_WORD_N()
	MOVD 32(R1), R2
	MUL_WORD_N()
	MOVD 40(R1), R2
	MUL_WORD_N()

	// reduce if necessary
	SUBS R16, R9, R16
	SBCS R17, R10, R17
	SBCS R19, R11, R19
	SBCS R20, R12, R20
	SBCS R21, R13, R21
	SBCS R22, R14, R22
	CSEL CS, R16, R9, R9
	CSEL CS, R17, R10, R10
	CSEL CS, R19, R11, R11
	CSEL CS, R20, R12, R12
	CSEL CS, R21, R13, R13
	CSEL CS, R22, R14, R14
	MOVD res+0(FP), R0
	STP  (R9, R10), 0(R0)
	STP  (R11, R12), 16(R0)
	STP  (R13, R14), 32(R0)
	RET
