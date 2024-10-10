package poseidon2

import "github.com/consensys/gnark-crypto/ecc/bn254/fr"

// poseidon
// https://github.com/argumentcomputer/neptune/blob/main/spec/poseidon_spec.pdf

// poseidon2 ref implem
// https://github.com/HorizenLabs/poseidon2/blob/main/plain_implementations/src/poseidon2/poseidon2.rs

// M ∈ {80,128,256}, security level in bits

// Hash stores the state of the poseidon2 permutation and provides poseidon2 permutation
// methods on the state
type Hash struct {

	// len(preimage)+len(digest)=len(preimage)+ceil(log(2*<security_level>/r))
	t int

	// sbox degree
	d int

	// state
	state []fr.Element

	// number of full rounds (even number)
	rF int

	// number of partial rounds
	rP int
}

// sBox applies the sBox on state[index]
func (h *Hash) sBox(index int) {
	var tmp fr.Element
	tmp.Set(&h.state[index])
	if h.d == 3 {
		h.state[index].Square(&h.state[index]).
			Mul(&h.state[index], &tmp)
	} else if h.d == 5 {
		h.state[index].Square(&h.state[index]).
			Square(&h.state[index]).
			Mul(&h.state[index], &tmp)
	} else if h.d == 7 {
		h.state[index].Square(&h.state[index]).
			Mul(&h.state[index], &tmp).
			Square(&h.state[index]).
			Mul(&h.state[index], &tmp)
	}
}

// matMulM4 computes
// s <- M4*s
// where M4=
// (5 7 1 3)
// (4 6 1 1)
// (1 3 5 7)
// (1 1 4 6)
// see https://eprint.iacr.org/2023/323.pdf appendix B for the addition chain
func (h *Hash) matMulM4InPlace(s []fr.Element) {

	var t0, t1, t2, t3, t4, t5, t6, t7 fr.Element
	t0.Add(&s[0], &s[1])                     // s0+s1
	t1.Add(&s[2], &s[3])                     // s2+s3
	t2.Double(&s[1]).Add(&t2, &t1)           // 2s1+t1
	t3.Double(&s[3]).Add(&t3, &t0)           // 2s3+t0
	t4.Double(&t1).Double(&t4).Add(&t4, &t3) // 4t1+t3
	t5.Double(&t0).Double(&t5).Add(&t5, &t2) // 4t0+t2
	t6.Add(&t3, &t5)                         // t3+t4
	t7.Add(&t2, &t4)                         // t2+t4
	s[0].Set(&t6)
	s[1].Set(&t5)
	s[2].Set(&t7)
	s[3].Set(&t4)
}
