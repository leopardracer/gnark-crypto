// Code generated by gnark-crypto/generator. DO NOT EDIT.
// Functions are derived from Dag Arne Osvik's work in github.com/a16z/vectorized-fields

// addVec(res, a, b *Element, n uint64) res[0...n] = a[0...n] + b[0...n]
TEXT ·addVec(SB), NOSPLIT, $0-32
	MOVQ res+0(FP), CX
	MOVQ a+8(FP), AX
	MOVQ b+16(FP), DX
	MOVQ n+24(FP), BX

loop_1:
	TESTQ BX, BX
	JEQ   done_2 // n == 0, we are done

	// a[0] -> SI
	// a[1] -> DI
	// a[2] -> R8
	// a[3] -> R9
	MOVQ 0(AX), SI
	MOVQ 8(AX), DI
	MOVQ 16(AX), R8
	MOVQ 24(AX), R9
	ADDQ 0(DX), SI
	ADCQ 8(DX), DI
	ADCQ 16(DX), R8
	ADCQ 24(DX), R9

	// reduce element(SI,DI,R8,R9) using temp registers (R10,R11,R12,R13)
	REDUCE(SI,DI,R8,R9,R10,R11,R12,R13)

	MOVQ SI, 0(CX)
	MOVQ DI, 8(CX)
	MOVQ R8, 16(CX)
	MOVQ R9, 24(CX)

	// increment pointers to visit next element
	ADDQ $32, AX
	ADDQ $32, DX
	ADDQ $32, CX
	DECQ BX      // decrement n
	JMP  loop_1

done_2:
	RET

// subVec(res, a, b *Element, n uint64) res[0...n] = a[0...n] - b[0...n]
TEXT ·subVec(SB), NOSPLIT, $0-32
	MOVQ res+0(FP), CX
	MOVQ a+8(FP), AX
	MOVQ b+16(FP), DX
	MOVQ n+24(FP), BX
	XORQ SI, SI

loop_3:
	TESTQ BX, BX
	JEQ   done_4 // n == 0, we are done

	// a[0] -> DI
	// a[1] -> R8
	// a[2] -> R9
	// a[3] -> R10
	MOVQ 0(AX), DI
	MOVQ 8(AX), R8
	MOVQ 16(AX), R9
	MOVQ 24(AX), R10
	SUBQ 0(DX), DI
	SBBQ 8(DX), R8
	SBBQ 16(DX), R9
	SBBQ 24(DX), R10

	// reduce (a-b) mod q
	// q[0] -> R11
	// q[1] -> R12
	// q[2] -> R13
	// q[3] -> R14
	MOVQ    $const_q0, R11
	MOVQ    $const_q1, R12
	MOVQ    $const_q2, R13
	MOVQ    $const_q3, R14
	CMOVQCC SI, R11
	CMOVQCC SI, R12
	CMOVQCC SI, R13
	CMOVQCC SI, R14

	// add registers (q or 0) to a, and set to result
	ADDQ R11, DI
	ADCQ R12, R8
	ADCQ R13, R9
	ADCQ R14, R10
	MOVQ DI, 0(CX)
	MOVQ R8, 8(CX)
	MOVQ R9, 16(CX)
	MOVQ R10, 24(CX)

	// increment pointers to visit next element
	ADDQ $32, AX
	ADDQ $32, DX
	ADDQ $32, CX
	DECQ BX      // decrement n
	JMP  loop_3

done_4:
	RET

// scalarMulVec(res, a, b *Element, n uint64) res[0...n] = a[0...n] * b
TEXT ·scalarMulVec(SB), $56-32
	CMPB ·supportAdx(SB), $1
	JNE  noAdx_5
	MOVQ a+8(FP), R11
	MOVQ b+16(FP), R10
	MOVQ n+24(FP), R12

	// scalar[0] -> SI
	// scalar[1] -> DI
	// scalar[2] -> R8
	// scalar[3] -> R9
	MOVQ 0(R10), SI
	MOVQ 8(R10), DI
	MOVQ 16(R10), R8
	MOVQ 24(R10), R9
	MOVQ res+0(FP), R10

loop_6:
	TESTQ R12, R12
	JEQ   done_7   // n == 0, we are done

	// TODO @gbotrel this is generated from the same macro as the unit mul, we should refactor this in a single asm function
	// A -> BP
	// t[0] -> R14
	// t[1] -> R15
	// t[2] -> CX
	// t[3] -> BX
	// clear the flags
	XORQ AX, AX
	MOVQ 0(R11), DX

	// (A,t[0])  := x[0]*y[0] + A
	MULXQ SI, R14, R15

	// (A,t[1])  := x[1]*y[0] + A
	MULXQ DI, AX, CX
	ADOXQ AX, R15

	// (A,t[2])  := x[2]*y[0] + A
	MULXQ R8, AX, BX
	ADOXQ AX, CX

	// (A,t[3])  := x[3]*y[0] + A
	MULXQ R9, AX, BP
	ADOXQ AX, BX

	// A += carries from ADCXQ and ADOXQ
	MOVQ  $0, AX
	ADOXQ AX, BP

	// m := t[0]*q'[0] mod W
	MOVQ  $const_qInvNeg, DX
	IMULQ R14, DX

	// clear the flags
	XORQ AX, AX

	// C,_ := t[0] + m*q[0]
	MULXQ ·qElement+0(SB), AX, R13
	ADCXQ R14, AX
	MOVQ  R13, R14

	// (C,t[0]) := t[1] + m*q[1] + C
	ADCXQ R15, R14
	MULXQ ·qElement+8(SB), AX, R15
	ADOXQ AX, R14

	// (C,t[1]) := t[2] + m*q[2] + C
	ADCXQ CX, R15
	MULXQ ·qElement+16(SB), AX, CX
	ADOXQ AX, R15

	// (C,t[2]) := t[3] + m*q[3] + C
	ADCXQ BX, CX
	MULXQ ·qElement+24(SB), AX, BX
	ADOXQ AX, CX

	// t[3] = C + A
	MOVQ  $0, AX
	ADCXQ AX, BX
	ADOXQ BP, BX

	// clear the flags
	XORQ AX, AX
	MOVQ 8(R11), DX

	// (A,t[0])  := t[0] + x[0]*y[1] + A
	MULXQ SI, AX, BP
	ADOXQ AX, R14

	// (A,t[1])  := t[1] + x[1]*y[1] + A
	ADCXQ BP, R15
	MULXQ DI, AX, BP
	ADOXQ AX, R15

	// (A,t[2])  := t[2] + x[2]*y[1] + A
	ADCXQ BP, CX
	MULXQ R8, AX, BP
	ADOXQ AX, CX

	// (A,t[3])  := t[3] + x[3]*y[1] + A
	ADCXQ BP, BX
	MULXQ R9, AX, BP
	ADOXQ AX, BX

	// A += carries from ADCXQ and ADOXQ
	MOVQ  $0, AX
	ADCXQ AX, BP
	ADOXQ AX, BP

	// m := t[0]*q'[0] mod W
	MOVQ  $const_qInvNeg, DX
	IMULQ R14, DX

	// clear the flags
	XORQ AX, AX

	// C,_ := t[0] + m*q[0]
	MULXQ ·qElement+0(SB), AX, R13
	ADCXQ R14, AX
	MOVQ  R13, R14

	// (C,t[0]) := t[1] + m*q[1] + C
	ADCXQ R15, R14
	MULXQ ·qElement+8(SB), AX, R15
	ADOXQ AX, R14

	// (C,t[1]) := t[2] + m*q[2] + C
	ADCXQ CX, R15
	MULXQ ·qElement+16(SB), AX, CX
	ADOXQ AX, R15

	// (C,t[2]) := t[3] + m*q[3] + C
	ADCXQ BX, CX
	MULXQ ·qElement+24(SB), AX, BX
	ADOXQ AX, CX

	// t[3] = C + A
	MOVQ  $0, AX
	ADCXQ AX, BX
	ADOXQ BP, BX

	// clear the flags
	XORQ AX, AX
	MOVQ 16(R11), DX

	// (A,t[0])  := t[0] + x[0]*y[2] + A
	MULXQ SI, AX, BP
	ADOXQ AX, R14

	// (A,t[1])  := t[1] + x[1]*y[2] + A
	ADCXQ BP, R15
	MULXQ DI, AX, BP
	ADOXQ AX, R15

	// (A,t[2])  := t[2] + x[2]*y[2] + A
	ADCXQ BP, CX
	MULXQ R8, AX, BP
	ADOXQ AX, CX

	// (A,t[3])  := t[3] + x[3]*y[2] + A
	ADCXQ BP, BX
	MULXQ R9, AX, BP
	ADOXQ AX, BX

	// A += carries from ADCXQ and ADOXQ
	MOVQ  $0, AX
	ADCXQ AX, BP
	ADOXQ AX, BP

	// m := t[0]*q'[0] mod W
	MOVQ  $const_qInvNeg, DX
	IMULQ R14, DX

	// clear the flags
	XORQ AX, AX

	// C,_ := t[0] + m*q[0]
	MULXQ ·qElement+0(SB), AX, R13
	ADCXQ R14, AX
	MOVQ  R13, R14

	// (C,t[0]) := t[1] + m*q[1] + C
	ADCXQ R15, R14
	MULXQ ·qElement+8(SB), AX, R15
	ADOXQ AX, R14

	// (C,t[1]) := t[2] + m*q[2] + C
	ADCXQ CX, R15
	MULXQ ·qElement+16(SB), AX, CX
	ADOXQ AX, R15

	// (C,t[2]) := t[3] + m*q[3] + C
	ADCXQ BX, CX
	MULXQ ·qElement+24(SB), AX, BX
	ADOXQ AX, CX

	// t[3] = C + A
	MOVQ  $0, AX
	ADCXQ AX, BX
	ADOXQ BP, BX

	// clear the flags
	XORQ AX, AX
	MOVQ 24(R11), DX

	// (A,t[0])  := t[0] + x[0]*y[3] + A
	MULXQ SI, AX, BP
	ADOXQ AX, R14

	// (A,t[1])  := t[1] + x[1]*y[3] + A
	ADCXQ BP, R15
	MULXQ DI, AX, BP
	ADOXQ AX, R15

	// (A,t[2])  := t[2] + x[2]*y[3] + A
	ADCXQ BP, CX
	MULXQ R8, AX, BP
	ADOXQ AX, CX

	// (A,t[3])  := t[3] + x[3]*y[3] + A
	ADCXQ BP, BX
	MULXQ R9, AX, BP
	ADOXQ AX, BX

	// A += carries from ADCXQ and ADOXQ
	MOVQ  $0, AX
	ADCXQ AX, BP
	ADOXQ AX, BP

	// m := t[0]*q'[0] mod W
	MOVQ  $const_qInvNeg, DX
	IMULQ R14, DX

	// clear the flags
	XORQ AX, AX

	// C,_ := t[0] + m*q[0]
	MULXQ ·qElement+0(SB), AX, R13
	ADCXQ R14, AX
	MOVQ  R13, R14

	// (C,t[0]) := t[1] + m*q[1] + C
	ADCXQ R15, R14
	MULXQ ·qElement+8(SB), AX, R15
	ADOXQ AX, R14

	// (C,t[1]) := t[2] + m*q[2] + C
	ADCXQ CX, R15
	MULXQ ·qElement+16(SB), AX, CX
	ADOXQ AX, R15

	// (C,t[2]) := t[3] + m*q[3] + C
	ADCXQ BX, CX
	MULXQ ·qElement+24(SB), AX, BX
	ADOXQ AX, CX

	// t[3] = C + A
	MOVQ  $0, AX
	ADCXQ AX, BX
	ADOXQ BP, BX

	// reduce t mod q
	// reduce element(R14,R15,CX,BX) using temp registers (R13,AX,DX,s0-8(SP))
	REDUCE(R14,R15,CX,BX,R13,AX,DX,s0-8(SP))

	MOVQ R14, 0(R10)
	MOVQ R15, 8(R10)
	MOVQ CX, 16(R10)
	MOVQ BX, 24(R10)

	// increment pointers to visit next element
	ADDQ $32, R11
	ADDQ $32, R10
	DECQ R12      // decrement n
	JMP  loop_6

done_7:
	RET

noAdx_5:
	MOVQ n+24(FP), DX
	MOVQ res+0(FP), AX
	MOVQ AX, (SP)
	MOVQ DX, 8(SP)
	MOVQ DX, 16(SP)
	MOVQ a+8(FP), AX
	MOVQ AX, 24(SP)
	MOVQ DX, 32(SP)
	MOVQ DX, 40(SP)
	MOVQ b+16(FP), AX
	MOVQ AX, 48(SP)
	CALL ·scalarMulVecGeneric(SB)
	RET

// sumVec(res, a *Element, n uint64) res = sum(a[0...n])
TEXT ·sumVec(SB), NOSPLIT, $0-24

	// Derived from https://github.com/a16z/vectorized-fields
	// The idea is to use Z registers to accumulate the sum of elements, 8 by 8
	// first, we handle the case where n % 8 != 0
	// then, we loop over the elements 8 by 8 and accumulate the sum in the Z registers
	// finally, we reduce the sum and store it in res
	//
	// when we move an element of a into a Z register, we use VPMOVZXDQ
	// let's note w0...w3 the 4 64bits words of ai: w0 = ai[0], w1 = ai[1], w2 = ai[2], w3 = ai[3]
	// VPMOVZXDQ(ai, Z0) will result in
	// Z0= [hi(w3), lo(w3), hi(w2), lo(w2), hi(w1), lo(w1), hi(w0), lo(w0)]
	// with hi(wi) the high 32 bits of wi and lo(wi) the low 32 bits of wi
	// we can safely add 2^32+1 times Z registers constructed this way without overflow
	// since each of this lo/hi bits are moved into a "64bits" slot
	// N = 2^64-1 / 2^32-1 = 2^32+1
	//
	// we then propagate the carry using ADOXQ and ADCXQ
	// r0 = w0l + lo(woh)
	// r1 = carry + hi(woh) + w1l + lo(w1h)
	// r2 = carry + hi(w1h) + w2l + lo(w2h)
	// r3 = carry + hi(w2h) + w3l + lo(w3h)
	// r4 = carry + hi(w3h)
	// we then reduce the sum using a single-word Barrett reduction
	// we pick mu = 2^288 / q; which correspond to 4.5 words max.
	// meaning we must guarantee that r4 fits in 32bits.
	// To do so, we reduce N to 2^32-1 (since r4 receives 2 carries max)

	MOVQ a+8(FP), R14
	MOVQ n+16(FP), R15

	// initialize accumulators Z0, Z1, Z2, Z3, Z4, Z5, Z6, Z7
	VXORPS    Z0, Z0, Z0
	VMOVDQA64 Z0, Z1
	VMOVDQA64 Z0, Z2
	VMOVDQA64 Z0, Z3
	VMOVDQA64 Z0, Z4
	VMOVDQA64 Z0, Z5
	VMOVDQA64 Z0, Z6
	VMOVDQA64 Z0, Z7

	// n % 8 -> CX
	// n / 8 -> R15
	MOVQ R15, CX
	ANDQ $7, CX
	SHRQ $3, R15

loop_single_10:
	TESTQ     CX, CX
	JEQ       loop8by8_8     // n % 8 == 0, we are going to loop over 8 by 8
	VPMOVZXDQ 0(R14), Z8
	VPADDQ    Z8, Z0, Z0
	ADDQ      $32, R14
	DECQ      CX             // decrement nMod8
	JMP       loop_single_10

loop8by8_8:
	TESTQ      R15, R15
	JEQ        accumulate_11  // n == 0, we are going to accumulate
	VPMOVZXDQ  0*32(R14), Z8
	VPMOVZXDQ  1*32(R14), Z9
	VPMOVZXDQ  2*32(R14), Z10
	VPMOVZXDQ  3*32(R14), Z11
	VPMOVZXDQ  4*32(R14), Z12
	VPMOVZXDQ  5*32(R14), Z13
	VPMOVZXDQ  6*32(R14), Z14
	VPMOVZXDQ  7*32(R14), Z15
	PREFETCHT0 256(R14)
	VPADDQ     Z8, Z0, Z0
	VPADDQ     Z9, Z1, Z1
	VPADDQ     Z10, Z2, Z2
	VPADDQ     Z11, Z3, Z3
	VPADDQ     Z12, Z4, Z4
	VPADDQ     Z13, Z5, Z5
	VPADDQ     Z14, Z6, Z6
	VPADDQ     Z15, Z7, Z7

	// increment pointers to visit next 8 elements
	ADDQ $256, R14
	DECQ R15        // decrement n
	JMP  loop8by8_8

accumulate_11:
	// accumulate the 8 Z registers into Z0
	VPADDQ Z7, Z6, Z6
	VPADDQ Z6, Z5, Z5
	VPADDQ Z5, Z4, Z4
	VPADDQ Z4, Z3, Z3
	VPADDQ Z3, Z2, Z2
	VPADDQ Z2, Z1, Z1
	VPADDQ Z1, Z0, Z0

	// carry propagation
	// lo(w0) -> BX
	// hi(w0) -> SI
	// lo(w1) -> DI
	// hi(w1) -> R8
	// lo(w2) -> R9
	// hi(w2) -> R10
	// lo(w3) -> R11
	// hi(w3) -> R12
	VMOVQ   X0, BX
	VALIGNQ $1, Z0, Z0, Z0
	VMOVQ   X0, SI
	VALIGNQ $1, Z0, Z0, Z0
	VMOVQ   X0, DI
	VALIGNQ $1, Z0, Z0, Z0
	VMOVQ   X0, R8
	VALIGNQ $1, Z0, Z0, Z0
	VMOVQ   X0, R9
	VALIGNQ $1, Z0, Z0, Z0
	VMOVQ   X0, R10
	VALIGNQ $1, Z0, Z0, Z0
	VMOVQ   X0, R11
	VALIGNQ $1, Z0, Z0, Z0
	VMOVQ   X0, R12

	// lo(hi(wo)) -> R13
	// lo(hi(w1)) -> CX
	// lo(hi(w2)) -> R15
	// lo(hi(w3)) -> R14
#define SPLIT_LO_HI(in0, in1) \
	MOVQ in1, in0         \
	ANDQ $0xffffffff, in0 \
	SHLQ $32, in0         \
	SHRQ $32, in1         \

	SPLIT_LO_HI(R13, SI)
	SPLIT_LO_HI(CX, R8)
	SPLIT_LO_HI(R15, R10)
	SPLIT_LO_HI(R14, R12)

	// r0 = w0l + lo(woh)
	// r1 = carry + hi(woh) + w1l + lo(w1h)
	// r2 = carry + hi(w1h) + w2l + lo(w2h)
	// r3 = carry + hi(w2h) + w3l + lo(w3h)
	// r4 = carry + hi(w3h)

	XORQ  AX, AX   // clear the flags
	ADOXQ R13, BX
	ADOXQ CX, DI
	ADCXQ SI, DI
	ADOXQ R15, R9
	ADCXQ R8, R9
	ADOXQ R14, R11
	ADCXQ R10, R11
	ADOXQ AX, R12
	ADCXQ AX, R12

	// r[0] -> BX
	// r[1] -> DI
	// r[2] -> R9
	// r[3] -> R11
	// r[4] -> R12
	// reduce using single-word Barrett
	// see see Handbook of Applied Cryptography, Algorithm 14.42.
	// mu=2^288 / q -> SI
	MOVQ  $const_mu, SI
	MOVQ  R11, AX
	SHRQ  $32, R12, AX
	MULQ  SI                       // high bits of res stored in DX
	MULXQ ·qElement+0(SB), AX, SI
	SUBQ  AX, BX
	SBBQ  SI, DI
	MULXQ ·qElement+16(SB), AX, SI
	SBBQ  AX, R9
	SBBQ  SI, R11
	SBBQ  $0, R12
	MULXQ ·qElement+8(SB), AX, SI
	SUBQ  AX, DI
	SBBQ  SI, R9
	MULXQ ·qElement+24(SB), AX, SI
	SBBQ  AX, R11
	SBBQ  SI, R12
	MOVQ  BX, R8
	MOVQ  DI, R10
	MOVQ  R9, R13
	MOVQ  R11, CX
	SUBQ  ·qElement+0(SB), BX
	SBBQ  ·qElement+8(SB), DI
	SBBQ  ·qElement+16(SB), R9
	SBBQ  ·qElement+24(SB), R11
	SBBQ  $0, R12
	JCS   modReduced_12
	MOVQ  BX, R8
	MOVQ  DI, R10
	MOVQ  R9, R13
	MOVQ  R11, CX
	SUBQ  ·qElement+0(SB), BX
	SBBQ  ·qElement+8(SB), DI
	SBBQ  ·qElement+16(SB), R9
	SBBQ  ·qElement+24(SB), R11
	SBBQ  $0, R12
	JCS   modReduced_12
	MOVQ  BX, R8
	MOVQ  DI, R10
	MOVQ  R9, R13
	MOVQ  R11, CX

modReduced_12:
	MOVQ res+0(FP), SI
	MOVQ R8, 0(SI)
	MOVQ R10, 8(SI)
	MOVQ R13, 16(SI)
	MOVQ CX, 24(SI)

done_9:
	RET

// innerProdVec(res, a,b *Element, n uint64) res = sum(a[0...n] * b[0...n])
TEXT ·innerProdVec(SB), NOSPLIT, $0-32
	MOVQ a+8(FP), R14
	MOVQ b+16(FP), R15
	MOVQ n+24(FP), CX

	// Create mask for low dword in each qword
	VPCMPEQB  Y0, Y0, Y0
	VPMOVZXDQ Y0, Z5
	VPXORQ    Z16, Z16, Z16
	VMOVDQA64 Z16, Z17
	VMOVDQA64 Z16, Z18
	VMOVDQA64 Z16, Z19
	VMOVDQA64 Z16, Z20
	VMOVDQA64 Z16, Z21
	VMOVDQA64 Z16, Z22
	VMOVDQA64 Z16, Z23
	VMOVDQA64 Z16, Z24
	VMOVDQA64 Z16, Z25
	VMOVDQA64 Z16, Z26
	VMOVDQA64 Z16, Z27
	VMOVDQA64 Z16, Z28
	VMOVDQA64 Z16, Z29
	VMOVDQA64 Z16, Z30
	VMOVDQA64 Z16, Z31
	TESTQ     CX, CX
	JEQ       done_14       // n == 0, we are done

loop_13:
	TESTQ     CX, CX
	JEQ       accumulate_15 // n == 0 we can accumulate
	VPMOVZXDQ (R15), Z4
	ADDQ      $32, R15

	// we multiply and accumulate partial products of 4 bytes * 32 bytes
#define MAC(in0, in1, in2) \
	VPMULUDQ.BCST in0, Z4, Z2  \
	VPSRLQ        $32, Z2, Z3  \
	VPANDQ        Z5, Z2, Z2   \
	VPADDQ        Z2, in1, in1 \
	VPADDQ        Z3, in2, in2 \

	MAC(0*4(R14), Z16, Z24)
	MAC(1*4(R14), Z17, Z25)
	MAC(2*4(R14), Z18, Z26)
	MAC(3*4(R14), Z19, Z27)
	MAC(4*4(R14), Z20, Z28)
	MAC(5*4(R14), Z21, Z29)
	MAC(6*4(R14), Z22, Z30)
	MAC(7*4(R14), Z23, Z31)
	ADDQ $32, R14
	DECQ CX       // decrement n
	JMP  loop_13

accumulate_15:
	// we accumulate the partial products into 544bits in Z1:Z0
	MOVQ  $0x0000000000001555, AX
	KMOVD AX, K1
	MOVQ  $1, AX
	KMOVD AX, K2

	// store the least significant 32 bits of ACC (starts with A0L) in Z0
	VALIGND.Z $16, Z16, Z16, K2, Z0
	KSHIFTLW  $1, K2, K2
	VPSRLQ    $32, Z16, Z2
	VALIGND.Z $2, Z16, Z16, K1, Z16
	VPADDQ    Z2, Z16, Z16
	VPANDQ    Z5, Z24, Z2
	VPADDQ    Z2, Z16, Z16
	VPANDQ    Z5, Z17, Z2
	VPADDQ    Z2, Z16, Z16
	VALIGND   $15, Z16, Z16, K2, Z0
	KSHIFTLW  $1, K2, K2

	// macro to add partial products and store the result in Z0
#define ADDPP(in0, in1, in2, in3, in4) \
	VPSRLQ    $32, Z16, Z2              \
	VALIGND.Z $2, Z16, Z16, K1, Z16     \
	VPADDQ    Z2, Z16, Z16              \
	VPSRLQ    $32, in0, in0             \
	VPADDQ    in0, Z16, Z16             \
	VPSRLQ    $32, in1, in1             \
	VPADDQ    in1, Z16, Z16             \
	VPANDQ    Z5, in2, Z2               \
	VPADDQ    Z2, Z16, Z16              \
	VPANDQ    Z5, in3, Z2               \
	VPADDQ    Z2, Z16, Z16              \
	VALIGND   $16-in4, Z16, Z16, K2, Z0 \
	KADDW     K2, K2, K2                \

	ADDPP(Z24, Z17, Z25, Z18, 2)
	ADDPP(Z25, Z18, Z26, Z19, 3)
	ADDPP(Z26, Z19, Z27, Z20, 4)
	ADDPP(Z27, Z20, Z28, Z21, 5)
	ADDPP(Z28, Z21, Z29, Z22, 6)
	ADDPP(Z29, Z22, Z30, Z23, 7)
	VPSRLQ    $32, Z16, Z2
	VALIGND.Z $2, Z16, Z16, K1, Z16
	VPADDQ    Z2, Z16, Z16
	VPSRLQ    $32, Z30, Z30
	VPADDQ    Z30, Z16, Z16
	VPSRLQ    $32, Z23, Z23
	VPADDQ    Z23, Z16, Z16
	VPANDQ    Z5, Z31, Z2
	VPADDQ    Z2, Z16, Z16
	VALIGND   $16-8, Z16, Z16, K2, Z0
	KSHIFTLW  $1, K2, K2
	VPSRLQ    $32, Z16, Z2
	VALIGND.Z $2, Z16, Z16, K1, Z16
	VPADDQ    Z2, Z16, Z16
	VPSRLQ    $32, Z31, Z31
	VPADDQ    Z31, Z16, Z16
	VALIGND   $16-9, Z16, Z16, K2, Z0
	KSHIFTLW  $1, K2, K2

#define ADDPP2(in0) \
	VPSRLQ    $32, Z16, Z2              \
	VALIGND.Z $2, Z16, Z16, K1, Z16     \
	VPADDQ    Z2, Z16, Z16              \
	VALIGND   $16-in0, Z16, Z16, K2, Z0 \
	KSHIFTLW  $1, K2, K2                \

	ADDPP2(10)
	ADDPP2(11)
	ADDPP2(12)
	ADDPP2(13)
	ADDPP2(14)
	ADDPP2(15)
	VPSRLQ      $32, Z16, Z2
	VALIGND.Z   $2, Z16, Z16, K1, Z16
	VPADDQ      Z2, Z16, Z16
	VMOVDQA64.Z Z16, K1, Z1

	// Extract the 4 least significant qwords of Z0
	VMOVQ   X0, SI
	VALIGNQ $1, Z0, Z1, Z0
	VMOVQ   X0, DI
	VALIGNQ $1, Z0, Z0, Z0
	VMOVQ   X0, R8
	VALIGNQ $1, Z0, Z0, Z0
	VMOVQ   X0, R9
	VALIGNQ $1, Z0, Z0, Z0
	XORQ    BX, BX
	MOVQ    $const_qInvNeg, DX
	MULXQ   SI, DX, R10
	MULXQ   ·qElement+0(SB), AX, R10
	ADDQ    AX, SI
	ADCQ    R10, DI
	MULXQ   ·qElement+16(SB), AX, R10
	ADCQ    AX, R8
	ADCQ    R10, R9
	ADCQ    $0, BX
	MULXQ   ·qElement+8(SB), AX, R10
	ADDQ    AX, DI
	ADCQ    R10, R8
	MULXQ   ·qElement+24(SB), AX, R10
	ADCQ    AX, R9
	ADCQ    R10, BX
	ADCQ    $0, SI
	MOVQ    $const_qInvNeg, DX
	MULXQ   DI, DX, R10
	MULXQ   ·qElement+0(SB), AX, R10
	ADDQ    AX, DI
	ADCQ    R10, R8
	MULXQ   ·qElement+16(SB), AX, R10
	ADCQ    AX, R9
	ADCQ    R10, BX
	ADCQ    $0, SI
	MULXQ   ·qElement+8(SB), AX, R10
	ADDQ    AX, R8
	ADCQ    R10, R9
	MULXQ   ·qElement+24(SB), AX, R10
	ADCQ    AX, BX
	ADCQ    R10, SI
	ADCQ    $0, DI
	MOVQ    $const_qInvNeg, DX
	MULXQ   R8, DX, R10
	MULXQ   ·qElement+0(SB), AX, R10
	ADDQ    AX, R8
	ADCQ    R10, R9
	MULXQ   ·qElement+16(SB), AX, R10
	ADCQ    AX, BX
	ADCQ    R10, SI
	ADCQ    $0, DI
	MULXQ   ·qElement+8(SB), AX, R10
	ADDQ    AX, R9
	ADCQ    R10, BX
	MULXQ   ·qElement+24(SB), AX, R10
	ADCQ    AX, SI
	ADCQ    R10, DI
	ADCQ    $0, R8
	MOVQ    $const_qInvNeg, DX
	MULXQ   R9, DX, R10
	MULXQ   ·qElement+0(SB), AX, R10
	ADDQ    AX, R9
	ADCQ    R10, BX
	MULXQ   ·qElement+16(SB), AX, R10
	ADCQ    AX, SI
	ADCQ    R10, DI
	ADCQ    $0, R8
	MULXQ   ·qElement+8(SB), AX, R10
	ADDQ    AX, BX
	ADCQ    R10, SI
	MULXQ   ·qElement+24(SB), AX, R10
	ADCQ    AX, DI
	ADCQ    R10, R8
	ADCQ    $0, R9
	VMOVQ   X0, AX
	ADDQ    AX, BX
	VALIGNQ $1, Z0, Z0, Z0
	VMOVQ   X0, AX
	ADCQ    AX, SI
	VALIGNQ $1, Z0, Z0, Z0
	VMOVQ   X0, AX
	ADCQ    AX, DI
	VALIGNQ $1, Z0, Z0, Z0
	VMOVQ   X0, AX
	ADCQ    AX, R8
	VALIGNQ $1, Z0, Z0, Z0
	VMOVQ   X0, AX
	ADCQ    AX, R9

	// Barrett reduction; see Handbook of Applied Cryptography, Algorithm 14.42.
	MOVQ  R8, AX
	SHRQ  $32, R9, AX
	MOVQ  $const_mu, DX
	MULQ  DX
	MULXQ ·qElement+0(SB), AX, R10
	SUBQ  AX, BX
	SBBQ  R10, SI
	MULXQ ·qElement+16(SB), AX, R10
	SBBQ  AX, DI
	SBBQ  R10, R8
	SBBQ  $0, R9
	MULXQ ·qElement+8(SB), AX, R10
	SUBQ  AX, SI
	SBBQ  R10, DI
	MULXQ ·qElement+24(SB), AX, R10
	SBBQ  AX, R8
	SBBQ  R10, R9

	// we need up to 2 conditional substractions to be < q
	MOVQ res+0(FP), R11
	MOVQ BX, 0(R11)
	MOVQ SI, 8(R11)
	MOVQ DI, 16(R11)
	MOVQ R8, 24(R11)
	SUBQ ·qElement+0(SB), BX
	SBBQ ·qElement+8(SB), SI
	SBBQ ·qElement+16(SB), DI
	SBBQ ·qElement+24(SB), R8
	SBBQ $0, R9
	JCS  done_14
	MOVQ BX, 0(R11)
	MOVQ SI, 8(R11)
	MOVQ DI, 16(R11)
	MOVQ R8, 24(R11)
	SUBQ ·qElement+0(SB), BX
	SBBQ ·qElement+8(SB), SI
	SBBQ ·qElement+16(SB), DI
	SBBQ ·qElement+24(SB), R8
	SBBQ $0, R9
	JCS  done_14
	MOVQ BX, 0(R11)
	MOVQ SI, 8(R11)
	MOVQ DI, 16(R11)
	MOVQ R8, 24(R11)

done_14:
	RET

// mulVec(res, a,b *Element, n uint64, qInvNeg uint64) res = a[0...n] * b[0...n]
TEXT ·mulVec(SB), $8-40
	// couple of defines
#define AVX_MUL_Q_LO() \
	VPMULUDQ.BCST ·qElement+0(SB), Z9, Z10  \
	VPADDQ        Z10, Z0, Z0               \
	VPMULUDQ.BCST ·qElement+4(SB), Z9, Z11  \
	VPADDQ        Z11, Z1, Z1               \
	VPMULUDQ.BCST ·qElement+8(SB), Z9, Z12  \
	VPADDQ        Z12, Z2, Z2               \
	VPMULUDQ.BCST ·qElement+12(SB), Z9, Z13 \
	VPADDQ        Z13, Z3, Z3               \

#define AVX_MUL_Q_HI() \
	VPMULUDQ.BCST ·qElement+16(SB), Z9, Z14 \
	VPADDQ        Z14, Z4, Z4               \
	VPMULUDQ.BCST ·qElement+20(SB), Z9, Z15 \
	VPADDQ        Z15, Z5, Z5               \
	VPMULUDQ.BCST ·qElement+24(SB), Z9, Z16 \
	VPADDQ        Z16, Z6, Z6               \
	VPMULUDQ.BCST ·qElement+28(SB), Z9, Z17 \
	VPADDQ        Z17, Z7, Z7               \

#define CARRY1() \
	VPSRLQ $32, Z0, Z10 \
	VPADDQ Z10, Z1, Z1  \
	VPANDQ Z8, Z1, Z0   \
	VPSRLQ $32, Z1, Z11 \
	VPADDQ Z11, Z2, Z2  \
	VPANDQ Z8, Z2, Z1   \
	VPSRLQ $32, Z2, Z12 \
	VPADDQ Z12, Z3, Z3  \
	VPANDQ Z8, Z3, Z2   \
	VPSRLQ $32, Z3, Z13 \
	VPADDQ Z13, Z4, Z4  \
	VPANDQ Z8, Z4, Z3   \

#define CARRY2() \
	VPSRLQ $32, Z4, Z14 \
	VPADDQ Z14, Z5, Z5  \
	VPANDQ Z8, Z5, Z4   \
	VPSRLQ $32, Z5, Z15 \
	VPADDQ Z15, Z6, Z6  \
	VPANDQ Z8, Z6, Z5   \
	VPSRLQ $32, Z6, Z16 \
	VPADDQ Z16, Z7, Z7  \
	VPANDQ Z8, Z7, Z6   \
	VPSRLQ $32, Z7, Z7  \

#define CARRY3() \
	VPSRLQ $32, Z0, Z10 \
	VPANDQ Z8, Z0, Z0   \
	VPADDQ Z10, Z1, Z1  \
	VPSRLQ $32, Z1, Z11 \
	VPANDQ Z8, Z1, Z1   \
	VPADDQ Z11, Z2, Z2  \
	VPSRLQ $32, Z2, Z12 \
	VPANDQ Z8, Z2, Z2   \
	VPADDQ Z12, Z3, Z3  \
	VPSRLQ $32, Z3, Z13 \
	VPANDQ Z8, Z3, Z3   \
	VPADDQ Z13, Z4, Z4  \

#define CARRY4() \
	VPSRLQ $32, Z4, Z14 \
	VPANDQ Z8, Z4, Z4   \
	VPADDQ Z14, Z5, Z5  \
	VPSRLQ $32, Z5, Z15 \
	VPANDQ Z8, Z5, Z5   \
	VPADDQ Z15, Z6, Z6  \
	VPSRLQ $32, Z6, Z16 \
	VPANDQ Z8, Z6, Z6   \
	VPADDQ Z16, Z7, Z7  \

#define MUL_WORD_0() \
	XORQ  AX, AX      \
	MULXQ R10, BX, SI \
	MULXQ R11, AX, DI \
	ADOXQ AX, SI      \
	MULXQ R12, AX, R8 \
	ADOXQ AX, DI      \
	MULXQ R13, AX, BP \
	ADOXQ AX, R8      \
	MOVQ  $0, AX      \
	ADOXQ AX, BP      \

#define MUL_WORD() \
	XORQ  AX, AX      \
	MULXQ R10, AX, BP \
	ADOXQ AX, BX      \
	ADCXQ BP, SI      \
	MULXQ R11, AX, BP \
	ADOXQ AX, SI      \
	ADCXQ BP, DI      \
	MULXQ R12, AX, BP \
	ADOXQ AX, DI      \
	ADCXQ BP, R8      \
	MULXQ R13, AX, BP \
	ADOXQ AX, R8      \
	MOVQ  $0, AX      \
	ADCXQ AX, BP      \
	ADOXQ AX, BP      \

#define DIV_SHIFT() \
	MOVQ  $const_qInvNeg, DX       \
	IMULQ BX, DX                   \
	XORQ  AX, AX                   \
	MULXQ ·qElement+0(SB), AX, R9  \
	ADCXQ BX, AX                   \
	MOVQ  R9, BX                   \
	ADCXQ SI, BX                   \
	MULXQ ·qElement+8(SB), AX, SI  \
	ADOXQ AX, BX                   \
	ADCXQ DI, SI                   \
	MULXQ ·qElement+16(SB), AX, DI \
	ADOXQ AX, SI                   \
	ADCXQ R8, DI                   \
	MULXQ ·qElement+24(SB), AX, R8 \
	ADOXQ AX, DI                   \
	MOVQ  $0, AX                   \
	ADCXQ AX, R8                   \
	ADOXQ BP, R8                   \



	MOVQ      res+0(FP), R15
	MOVQ      a+8(FP), R14
	MOVQ      b+16(FP), CX
	MOVQ      n+24(FP), R9
	MOVQ      R9, s0-8(SP)
	VPCMPEQB  Y8, Y8, Y8
	VPMOVZXDQ Y8, Z8
	MOVQ      $0x5555, DX
	KMOVD     DX, K1

loop_17:
	TESTQ     R9, R9
	JEQ       done_16            // n == 0, we are done
	MOVQ      0(R14), DX
	VMOVDQU64 256+0*64(R14), Z16
	VMOVDQU64 256+1*64(R14), Z17
	VMOVDQU64 256+2*64(R14), Z18
	VMOVDQU64 256+3*64(R14), Z19

	// load input y[0]
	MOVQ      0(CX), R10
	MOVQ      8(CX), R11
	MOVQ      16(CX), R12
	MOVQ      24(CX), R13
	VMOVDQU64 256+0*64(CX), Z24
	VMOVDQU64 256+1*64(CX), Z25
	VMOVDQU64 256+2*64(CX), Z26
	VMOVDQU64 256+3*64(CX), Z27

	// Transpose and expand x and y
	VSHUFI64X2 $0x88, Z17, Z16, Z20
	VSHUFI64X2 $0xdd, Z17, Z16, Z22
	VSHUFI64X2 $0x88, Z19, Z18, Z21
	VSHUFI64X2 $0xdd, Z19, Z18, Z23
	VSHUFI64X2 $0x88, Z25, Z24, Z28
	VSHUFI64X2 $0xdd, Z25, Z24, Z30
	VSHUFI64X2 $0x88, Z27, Z26, Z29
	VSHUFI64X2 $0xdd, Z27, Z26, Z31
	VPERMQ     $0xd8, Z20, Z20
	VPERMQ     $0xd8, Z21, Z21
	VPERMQ     $0xd8, Z22, Z22
	VPERMQ     $0xd8, Z23, Z23

	// z[0] -> y * x[0]
	MUL_WORD_0()
	DIV_SHIFT()
	VPERMQ     $0xd8, Z28, Z28
	VPERMQ     $0xd8, Z29, Z29
	VPERMQ     $0xd8, Z30, Z30
	VPERMQ     $0xd8, Z31, Z31
	VSHUFI64X2 $0xd8, Z20, Z20, Z20
	VSHUFI64X2 $0xd8, Z21, Z21, Z21
	VSHUFI64X2 $0xd8, Z22, Z22, Z22
	VSHUFI64X2 $0xd8, Z23, Z23, Z23

	// z[0] -> y * x[1]
	MOVQ       8(R14), DX
	CALL      ·mul_xi(SB)
	VSHUFI64X2 $0xd8, Z28, Z28, Z28
	VSHUFI64X2 $0xd8, Z29, Z29, Z29
	VSHUFI64X2 $0xd8, Z30, Z30, Z30
	VSHUFI64X2 $0xd8, Z31, Z31, Z31
	VSHUFI64X2 $0x44, Z21, Z20, Z16
	VSHUFI64X2 $0xee, Z21, Z20, Z18
	VSHUFI64X2 $0x44, Z23, Z22, Z20
	VSHUFI64X2 $0xee, Z23, Z22, Z22

	// z[0] -> y * x[2]
	MOVQ       16(R14), DX
	CALL      ·mul_xi(SB)
	VSHUFI64X2 $0x44, Z29, Z28, Z24
	VSHUFI64X2 $0xee, Z29, Z28, Z26
	VSHUFI64X2 $0x44, Z31, Z30, Z28
	VSHUFI64X2 $0xee, Z31, Z30, Z30
	PREFETCHT0 1024(R14)
	VPSRLQ     $32, Z16, Z17
	VPSRLQ     $32, Z18, Z19
	VPSRLQ     $32, Z20, Z21
	VPSRLQ     $32, Z22, Z23
	VPSRLQ     $32, Z24, Z25
	VPSRLQ     $32, Z26, Z27
	VPSRLQ     $32, Z28, Z29
	VPSRLQ     $32, Z30, Z31

	// z[0] -> y * x[3]
	MOVQ   24(R14), DX
	CALL   ·mul_xi(SB)
	VPANDQ Z8, Z16, Z16
	VPANDQ Z8, Z18, Z18
	VPANDQ Z8, Z20, Z20
	VPANDQ Z8, Z22, Z22
	VPANDQ Z8, Z24, Z24
	VPANDQ Z8, Z26, Z26
	VPANDQ Z8, Z28, Z28
	VPANDQ Z8, Z30, Z30

	// reduce element(BX,SI,DI,R8) using temp registers (R10,R11,R12,R13)
	REDUCE(BX,SI,DI,R8,R10,R11,R12,R13)

	// store output z[0]
	MOVQ BX, 0(R15)
	MOVQ SI, 8(R15)
	MOVQ DI, 16(R15)
	MOVQ R8, 24(R15)
	ADDQ $32, R14
	MOVQ 0(R14), DX

	// load input y[1]
	MOVQ 32(CX), R10
	MOVQ 40(CX), R11
	MOVQ 48(CX), R12
	MOVQ 56(CX), R13

	// For each 256-bit input value, each zmm register now represents a 32-bit input word zero-extended to 64 bits.
	// Multiply y by doubleword 0 of x
	VPMULUDQ      Z16, Z24, Z0
	VPMULUDQ      Z16, Z25, Z1
	VPMULUDQ      Z16, Z26, Z2
	VPMULUDQ      Z16, Z27, Z3
	VPMULUDQ      Z16, Z28, Z4
	PREFETCHT0    1024(CX)
	VPMULUDQ      Z16, Z29, Z5
	VPMULUDQ      Z16, Z30, Z6
	VPMULUDQ      Z16, Z31, Z7
	VPMULUDQ.BCST qInvNeg+32(FP), Z0, Z9
	VPSRLQ        $32, Z0, Z10
	VPANDQ        Z8, Z0, Z0
	VPADDQ        Z10, Z1, Z1
	VPSRLQ        $32, Z1, Z11
	VPANDQ        Z8, Z1, Z1
	VPADDQ        Z11, Z2, Z2
	VPSRLQ        $32, Z2, Z12
	VPANDQ        Z8, Z2, Z2
	VPADDQ        Z12, Z3, Z3
	VPSRLQ        $32, Z3, Z13
	VPANDQ        Z8, Z3, Z3
	VPADDQ        Z13, Z4, Z4

	// z[1] -> y * x[0]
	MUL_WORD_0()
	DIV_SHIFT()
	VPSRLQ        $32, Z4, Z14
	VPANDQ        Z8, Z4, Z4
	VPADDQ        Z14, Z5, Z5
	VPSRLQ        $32, Z5, Z15
	VPANDQ        Z8, Z5, Z5
	VPADDQ        Z15, Z6, Z6
	VPSRLQ        $32, Z6, Z16
	VPANDQ        Z8, Z6, Z6
	VPADDQ        Z16, Z7, Z7
	VPMULUDQ.BCST ·qElement+0(SB), Z9, Z10
	VPADDQ        Z10, Z0, Z0
	VPMULUDQ.BCST ·qElement+4(SB), Z9, Z11
	VPADDQ        Z11, Z1, Z1
	VPMULUDQ.BCST ·qElement+8(SB), Z9, Z12
	VPADDQ        Z12, Z2, Z2
	VPMULUDQ.BCST ·qElement+12(SB), Z9, Z13
	VPADDQ        Z13, Z3, Z3

	// z[1] -> y * x[1]
	MOVQ          8(R14), DX
	CALL          ·mul_xi(SB)
	VPMULUDQ.BCST ·qElement+16(SB), Z9, Z14
	VPADDQ        Z14, Z4, Z4
	VPMULUDQ.BCST ·qElement+20(SB), Z9, Z15
	VPADDQ        Z15, Z5, Z5
	VPMULUDQ.BCST ·qElement+24(SB), Z9, Z16
	VPADDQ        Z16, Z6, Z6
	VPMULUDQ.BCST ·qElement+28(SB), Z9, Z10
	VPADDQ        Z10, Z7, Z7
	VPSRLQ        $32, Z0, Z10
	VPADDQ        Z10, Z1, Z1
	VPANDQ        Z8, Z1, Z0
	VPSRLQ        $32, Z1, Z11
	VPADDQ        Z11, Z2, Z2
	VPANDQ        Z8, Z2, Z1
	VPSRLQ        $32, Z2, Z12
	VPADDQ        Z12, Z3, Z3
	VPANDQ        Z8, Z3, Z2
	VPSRLQ        $32, Z3, Z13
	VPADDQ        Z13, Z4, Z4
	VPANDQ        Z8, Z4, Z3

	// z[1] -> y * x[2]
	MOVQ   16(R14), DX
	CALL   ·mul_xi(SB)
	VPSRLQ $32, Z4, Z14
	VPADDQ Z14, Z5, Z5
	VPANDQ Z8, Z5, Z4
	VPSRLQ $32, Z5, Z15
	VPADDQ Z15, Z6, Z6
	VPANDQ Z8, Z6, Z5
	VPSRLQ $32, Z6, Z16
	VPADDQ Z16, Z7, Z7
	VPANDQ Z8, Z7, Z6
	VPSRLQ $32, Z7, Z7

	// Process doubleword 1 of x
	VPMULUDQ Z17, Z24, Z10
	VPADDQ   Z10, Z0, Z0
	VPMULUDQ Z17, Z25, Z11
	VPADDQ   Z11, Z1, Z1
	VPMULUDQ Z17, Z26, Z12
	VPADDQ   Z12, Z2, Z2
	VPMULUDQ Z17, Z27, Z13
	VPADDQ   Z13, Z3, Z3

	// z[1] -> y * x[3]
	MOVQ          24(R14), DX
	CALL          ·mul_xi(SB)
	VPMULUDQ      Z17, Z28, Z14
	VPADDQ        Z14, Z4, Z4
	VPMULUDQ      Z17, Z29, Z15
	VPADDQ        Z15, Z5, Z5
	VPMULUDQ      Z17, Z30, Z16
	VPADDQ        Z16, Z6, Z6
	VPMULUDQ      Z17, Z31, Z17
	VPADDQ        Z17, Z7, Z7
	VPMULUDQ.BCST qInvNeg+32(FP), Z0, Z9

	// reduce element(BX,SI,DI,R8) using temp registers (R10,R11,R12,R13)
	REDUCE(BX,SI,DI,R8,R10,R11,R12,R13)

	// store output z[1]
	MOVQ BX, 32(R15)
	MOVQ SI, 40(R15)
	MOVQ DI, 48(R15)
	MOVQ R8, 56(R15)
	ADDQ $32, R14
	MOVQ 0(R14), DX

	// load input y[2]
	MOVQ 64(CX), R10
	MOVQ 72(CX), R11
	MOVQ 80(CX), R12
	MOVQ 88(CX), R13

	// Move high dwords to zmm10-16, add each to the corresponding low dword (propagate 32-bit carries)
	VPSRLQ $32, Z0, Z10
	VPANDQ Z8, Z0, Z0
	VPADDQ Z10, Z1, Z1
	VPSRLQ $32, Z1, Z11
	VPANDQ Z8, Z1, Z1
	VPADDQ Z11, Z2, Z2
	VPSRLQ $32, Z2, Z12
	VPANDQ Z8, Z2, Z2
	VPADDQ Z12, Z3, Z3
	VPSRLQ $32, Z3, Z13
	VPANDQ Z8, Z3, Z3
	VPADDQ Z13, Z4, Z4
	CARRY4()

	// z[2] -> y * x[0]
	MUL_WORD_0()
	DIV_SHIFT()
	AVX_MUL_Q_LO()
	AVX_MUL_Q_HI()

	// z[2] -> y * x[1]
	MOVQ 8(R14), DX
	CALL      ·mul_xi(SB)
	CARRY1()
	CARRY2()

	// z[2] -> y * x[2]
	MOVQ 16(R14), DX
	CALL      ·mul_xi(SB)

	// Process doubleword 2 of x
	VPMULUDQ      Z18, Z24, Z10
	VPADDQ        Z10, Z0, Z0
	VPMULUDQ      Z18, Z25, Z11
	VPADDQ        Z11, Z1, Z1
	VPMULUDQ      Z18, Z26, Z12
	VPADDQ        Z12, Z2, Z2
	VPMULUDQ      Z18, Z27, Z13
	VPADDQ        Z13, Z3, Z3
	VPMULUDQ      Z18, Z28, Z14
	VPADDQ        Z14, Z4, Z4
	VPMULUDQ      Z18, Z29, Z15
	VPADDQ        Z15, Z5, Z5
	VPMULUDQ      Z18, Z30, Z16
	VPADDQ        Z16, Z6, Z6
	VPMULUDQ      Z18, Z31, Z17
	VPADDQ        Z17, Z7, Z7
	VPMULUDQ.BCST qInvNeg+32(FP), Z0, Z9

	// z[2] -> y * x[3]
	MOVQ 24(R14), DX
	CALL      ·mul_xi(SB)

	// Move high dwords to zmm10-16, add each to the corresponding low dword (propagate 32-bit carries)
	CARRY3()

	// reduce element(BX,SI,DI,R8) using temp registers (R10,R11,R12,R13)
	REDUCE(BX,SI,DI,R8,R10,R11,R12,R13)

	// store output z[2]
	MOVQ BX, 64(R15)
	MOVQ SI, 72(R15)
	MOVQ DI, 80(R15)
	MOVQ R8, 88(R15)
	ADDQ $32, R14
	MOVQ 0(R14), DX

	// load input y[3]
	MOVQ 96(CX), R10
	MOVQ 104(CX), R11
	MOVQ 112(CX), R12
	MOVQ 120(CX), R13
	CARRY4()
	AVX_MUL_Q_LO()

	// z[3] -> y * x[0]
	MUL_WORD_0()
	DIV_SHIFT()
	AVX_MUL_Q_HI()
	CARRY1()

	// z[3] -> y * x[1]
	MOVQ 8(R14), DX
	CALL      ·mul_xi(SB)
	CARRY2()

	// Process doubleword 3 of x
	VPMULUDQ Z19, Z24, Z10
	VPADDQ   Z10, Z0, Z0
	VPMULUDQ Z19, Z25, Z11
	VPADDQ   Z11, Z1, Z1
	VPMULUDQ Z19, Z26, Z12
	VPADDQ   Z12, Z2, Z2
	VPMULUDQ Z19, Z27, Z13
	VPADDQ   Z13, Z3, Z3

	// z[3] -> y * x[2]
	MOVQ          16(R14), DX
	CALL          ·mul_xi(SB)
	VPMULUDQ      Z19, Z28, Z14
	VPADDQ        Z14, Z4, Z4
	VPMULUDQ      Z19, Z29, Z15
	VPADDQ        Z15, Z5, Z5
	VPMULUDQ      Z19, Z30, Z16
	VPADDQ        Z16, Z6, Z6
	VPMULUDQ      Z19, Z31, Z17
	VPADDQ        Z17, Z7, Z7
	VPMULUDQ.BCST qInvNeg+32(FP), Z0, Z9
	CARRY3()

	// z[3] -> y * x[3]
	MOVQ 24(R14), DX
	CALL      ·mul_xi(SB)
	CARRY4()

	// reduce element(BX,SI,DI,R8) using temp registers (R10,R11,R12,R13)
	REDUCE(BX,SI,DI,R8,R10,R11,R12,R13)

	// store output z[3]
	MOVQ BX, 96(R15)
	MOVQ SI, 104(R15)
	MOVQ DI, 112(R15)
	MOVQ R8, 120(R15)
	ADDQ $32, R14
	MOVQ 0(R14), DX

	// load input y[4]
	MOVQ 128(CX), R10
	MOVQ 136(CX), R11
	MOVQ 144(CX), R12
	MOVQ 152(CX), R13
	AVX_MUL_Q_LO()
	AVX_MUL_Q_HI()

	// z[4] -> y * x[0]
	MUL_WORD_0()
	DIV_SHIFT()

	// Propagate carries and shift down by one dword
	CARRY1()
	CARRY2()

	// z[4] -> y * x[1]
	MOVQ 8(R14), DX
	CALL      ·mul_xi(SB)

	// Process doubleword 4 of x
	VPMULUDQ      Z20, Z24, Z10
	VPADDQ        Z10, Z0, Z0
	VPMULUDQ      Z20, Z25, Z11
	VPADDQ        Z11, Z1, Z1
	VPMULUDQ      Z20, Z26, Z12
	VPADDQ        Z12, Z2, Z2
	VPMULUDQ      Z20, Z27, Z13
	VPADDQ        Z13, Z3, Z3
	VPMULUDQ      Z20, Z28, Z14
	VPADDQ        Z14, Z4, Z4
	VPMULUDQ      Z20, Z29, Z15
	VPADDQ        Z15, Z5, Z5
	VPMULUDQ      Z20, Z30, Z16
	VPADDQ        Z16, Z6, Z6
	VPMULUDQ      Z20, Z31, Z17
	VPADDQ        Z17, Z7, Z7
	VPMULUDQ.BCST qInvNeg+32(FP), Z0, Z9

	// z[4] -> y * x[2]
	MOVQ 16(R14), DX
	CALL      ·mul_xi(SB)

	// Move high dwords to zmm10-16, add each to the corresponding low dword (propagate 32-bit carries)
	CARRY3()
	CARRY4()

	// z[4] -> y * x[3]
	MOVQ 24(R14), DX
	CALL      ·mul_xi(SB)

	// zmm7 keeps all 64 bits
	AVX_MUL_Q_LO()
	AVX_MUL_Q_HI()

	// reduce element(BX,SI,DI,R8) using temp registers (R10,R11,R12,R13)
	REDUCE(BX,SI,DI,R8,R10,R11,R12,R13)

	// store output z[4]
	MOVQ BX, 128(R15)
	MOVQ SI, 136(R15)
	MOVQ DI, 144(R15)
	MOVQ R8, 152(R15)
	ADDQ $32, R14
	MOVQ 0(R14), DX

	// Propagate carries and shift down by one dword
	CARRY1()
	CARRY2()

	// load input y[5]
	MOVQ 160(CX), R10
	MOVQ 168(CX), R11
	MOVQ 176(CX), R12
	MOVQ 184(CX), R13

	// Process doubleword 5 of x
	VPMULUDQ Z21, Z24, Z10
	VPADDQ   Z10, Z0, Z0
	VPMULUDQ Z21, Z25, Z11
	VPADDQ   Z11, Z1, Z1
	VPMULUDQ Z21, Z26, Z12
	VPADDQ   Z12, Z2, Z2
	VPMULUDQ Z21, Z27, Z13
	VPADDQ   Z13, Z3, Z3
	VPMULUDQ Z21, Z28, Z14
	VPADDQ   Z14, Z4, Z4
	VPMULUDQ Z21, Z29, Z15
	VPADDQ   Z15, Z5, Z5
	VPMULUDQ Z21, Z30, Z16
	VPADDQ   Z16, Z6, Z6
	VPMULUDQ Z21, Z31, Z17
	VPADDQ   Z17, Z7, Z7

	// z[5] -> y * x[0]
	MUL_WORD_0()
	DIV_SHIFT()
	VPMULUDQ.BCST qInvNeg+32(FP), Z0, Z9

	// Move high dwords to zmm10-16, add each to the corresponding low dword (propagate 32-bit carries)
	CARRY3()
	CARRY4()

	// z[5] -> y * x[1]
	MOVQ 8(R14), DX
	CALL      ·mul_xi(SB)
	AVX_MUL_Q_LO()
	AVX_MUL_Q_HI()

	// z[5] -> y * x[2]
	MOVQ 16(R14), DX
	CALL      ·mul_xi(SB)
	CARRY1()
	CARRY2()

	// z[5] -> y * x[3]
	MOVQ 24(R14), DX
	CALL      ·mul_xi(SB)

	// Process doubleword 6 of x
	VPMULUDQ      Z22, Z24, Z10
	VPADDQ        Z10, Z0, Z0
	VPMULUDQ      Z22, Z25, Z11
	VPADDQ        Z11, Z1, Z1
	VPMULUDQ      Z22, Z26, Z12
	VPADDQ        Z12, Z2, Z2
	VPMULUDQ      Z22, Z27, Z13
	VPADDQ        Z13, Z3, Z3
	VPMULUDQ      Z22, Z28, Z14
	VPADDQ        Z14, Z4, Z4
	VPMULUDQ      Z22, Z29, Z15
	VPADDQ        Z15, Z5, Z5
	VPMULUDQ      Z22, Z30, Z16
	VPADDQ        Z16, Z6, Z6
	VPMULUDQ      Z22, Z31, Z17
	VPADDQ        Z17, Z7, Z7
	VPMULUDQ.BCST qInvNeg+32(FP), Z0, Z9

	// reduce element(BX,SI,DI,R8) using temp registers (R10,R11,R12,R13)
	REDUCE(BX,SI,DI,R8,R10,R11,R12,R13)

	// store output z[5]
	MOVQ BX, 160(R15)
	MOVQ SI, 168(R15)
	MOVQ DI, 176(R15)
	MOVQ R8, 184(R15)
	ADDQ $32, R14
	MOVQ 0(R14), DX

	// load input y[6]
	MOVQ 192(CX), R10
	MOVQ 200(CX), R11
	MOVQ 208(CX), R12
	MOVQ 216(CX), R13

	// Move high dwords to zmm10-16, add each to the corresponding low dword (propagate 32-bit carries)
	CARRY3()
	CARRY4()

	// z[6] -> y * x[0]
	MUL_WORD_0()
	DIV_SHIFT()
	AVX_MUL_Q_LO()
	AVX_MUL_Q_HI()

	// z[6] -> y * x[1]
	MOVQ 8(R14), DX
	CALL      ·mul_xi(SB)
	CARRY1()
	CARRY2()

	// z[6] -> y * x[2]
	MOVQ 16(R14), DX
	CALL      ·mul_xi(SB)

	// Process doubleword 7 of x
	VPMULUDQ      Z23, Z24, Z10
	VPADDQ        Z10, Z0, Z0
	VPMULUDQ      Z23, Z25, Z11
	VPADDQ        Z11, Z1, Z1
	VPMULUDQ      Z23, Z26, Z12
	VPADDQ        Z12, Z2, Z2
	VPMULUDQ      Z23, Z27, Z13
	VPADDQ        Z13, Z3, Z3
	VPMULUDQ      Z23, Z28, Z14
	VPADDQ        Z14, Z4, Z4
	VPMULUDQ      Z23, Z29, Z15
	VPADDQ        Z15, Z5, Z5
	VPMULUDQ      Z23, Z30, Z16
	VPADDQ        Z16, Z6, Z6
	VPMULUDQ      Z23, Z31, Z17
	VPADDQ        Z17, Z7, Z7
	VPMULUDQ.BCST qInvNeg+32(FP), Z0, Z9

	// z[6] -> y * x[3]
	MOVQ 24(R14), DX
	CALL      ·mul_xi(SB)
	CARRY3()

	// reduce element(BX,SI,DI,R8) using temp registers (R10,R11,R12,R13)
	REDUCE(BX,SI,DI,R8,R10,R11,R12,R13)

	// store output z[6]
	MOVQ BX, 192(R15)
	MOVQ SI, 200(R15)
	MOVQ DI, 208(R15)
	MOVQ R8, 216(R15)
	ADDQ $32, R14
	MOVQ 0(R14), DX
	CARRY4()

	// load input y[7]
	MOVQ 224(CX), R10
	MOVQ 232(CX), R11
	MOVQ 240(CX), R12
	MOVQ 248(CX), R13
	AVX_MUL_Q_LO()
	AVX_MUL_Q_HI()

	// z[7] -> y * x[0]
	MUL_WORD_0()
	DIV_SHIFT()
	CARRY1()
	CARRY2()

	// z[7] -> y * x[1]
	MOVQ 8(R14), DX
	CALL      ·mul_xi(SB)

	// Conditional subtraction of the modulus
	VPERMD.BCST.Z ·qElement+0(SB), Z8, K1, Z10
	VPERMD.BCST.Z ·qElement+4(SB), Z8, K1, Z11
	VPERMD.BCST.Z ·qElement+8(SB), Z8, K1, Z12
	VPERMD.BCST.Z ·qElement+12(SB), Z8, K1, Z13
	VPERMD.BCST.Z ·qElement+16(SB), Z8, K1, Z14
	VPERMD.BCST.Z ·qElement+20(SB), Z8, K1, Z15
	VPERMD.BCST.Z ·qElement+24(SB), Z8, K1, Z16
	VPERMD.BCST.Z ·qElement+28(SB), Z8, K1, Z17
	VPSUBQ        Z10, Z0, Z10
	VPSRLQ        $63, Z10, Z20
	VPANDQ        Z8, Z10, Z10
	VPSUBQ        Z11, Z1, Z11
	VPSUBQ        Z20, Z11, Z11
	VPSRLQ        $63, Z11, Z21
	VPANDQ        Z8, Z11, Z11
	VPSUBQ        Z12, Z2, Z12
	VPSUBQ        Z21, Z12, Z12
	VPSRLQ        $63, Z12, Z22
	VPANDQ        Z8, Z12, Z12
	VPSUBQ        Z13, Z3, Z13
	VPSUBQ        Z22, Z13, Z13
	VPSRLQ        $63, Z13, Z23
	VPANDQ        Z8, Z13, Z13
	VPSUBQ        Z14, Z4, Z14
	VPSUBQ        Z23, Z14, Z14
	VPSRLQ        $63, Z14, Z24
	VPANDQ        Z8, Z14, Z14
	VPSUBQ        Z15, Z5, Z15
	VPSUBQ        Z24, Z15, Z15
	VPSRLQ        $63, Z15, Z25
	VPANDQ        Z8, Z15, Z15
	VPSUBQ        Z16, Z6, Z16
	VPSUBQ        Z25, Z16, Z16
	VPSRLQ        $63, Z16, Z26
	VPANDQ        Z8, Z16, Z16
	VPSUBQ        Z17, Z7, Z17
	VPSUBQ        Z26, Z17, Z17
	VPMOVQ2M      Z17, K2
	KNOTB         K2, K2
	VMOVDQU64     Z10, K2, Z0
	VMOVDQU64     Z11, K2, Z1
	VMOVDQU64     Z12, K2, Z2
	VMOVDQU64     Z13, K2, Z3
	VMOVDQU64     Z14, K2, Z4
	VMOVDQU64     Z15, K2, Z5
	VMOVDQU64     Z16, K2, Z6
	VMOVDQU64     Z17, K2, Z7

	// z[7] -> y * x[2]
	MOVQ 16(R14), DX
	CALL      ·mul_xi(SB)

	// Transpose results back
	VALIGND   $0, ·pattern1+0(SB), Z11, Z11
	VALIGND   $0, ·pattern2+0(SB), Z12, Z12
	VALIGND   $0, ·pattern3+0(SB), Z13, Z13
	VALIGND   $0, ·pattern4+0(SB), Z14, Z14
	VPSLLQ    $32, Z1, Z1
	VPORQ     Z1, Z0, Z0
	VPSLLQ    $32, Z3, Z3
	VPORQ     Z3, Z2, Z1
	VPSLLQ    $32, Z5, Z5
	VPORQ     Z5, Z4, Z2
	VPSLLQ    $32, Z7, Z7
	VPORQ     Z7, Z6, Z3
	VMOVDQU64 Z0, Z4
	VMOVDQU64 Z2, Z6
	VPERMT2Q  Z1, Z11, Z0
	VPERMT2Q  Z4, Z12, Z1
	VPERMT2Q  Z3, Z11, Z2
	VPERMT2Q  Z6, Z12, Z3

	// z[7] -> y * x[3]
	MOVQ      24(R14), DX
	CALL      ·mul_xi(SB)
	VMOVDQU64 Z0, Z4
	VMOVDQU64 Z1, Z5
	VPERMT2Q  Z2, Z13, Z0
	VPERMT2Q  Z4, Z14, Z2
	VPERMT2Q  Z3, Z13, Z1
	VPERMT2Q  Z5, Z14, Z3

	// reduce element(BX,SI,DI,R8) using temp registers (R10,R11,R12,R13)
	REDUCE(BX,SI,DI,R8,R10,R11,R12,R13)

	// store output z[7]
	MOVQ BX, 224(R15)
	MOVQ SI, 232(R15)
	MOVQ DI, 240(R15)
	MOVQ R8, 248(R15)
	ADDQ $288, R14

	// Save AVX-512 results
	VMOVDQU64 Z0, 256+0*64(R15)
	VMOVDQU64 Z2, 256+1*64(R15)
	VMOVDQU64 Z1, 256+2*64(R15)
	VMOVDQU64 Z3, 256+3*64(R15)
	ADDQ      $512, R15
	ADDQ      $512, CX
	MOVQ      s0-8(SP), R9
	DECQ      R9                // decrement n
	MOVQ      R9, s0-8(SP)
	JMP       loop_17

done_16:
	RET



TEXT ·mul_xi(SB), NOSPLIT, $0-0 
	NO_LOCAL_POINTERS
	MUL_WORD()
	DIV_SHIFT()
	RET