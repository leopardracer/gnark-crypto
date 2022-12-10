// Copyright 2020 ConsenSys Software Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

// Code generated by consensys/gnark-crypto DO NOT EDIT

package gkr

import (
	"encoding/json"
	"fmt"
	"github.com/consensys/gnark-crypto/ecc/bw6-761/fr"
	"github.com/consensys/gnark-crypto/ecc/bw6-761/fr/mimc"
	"github.com/consensys/gnark-crypto/ecc/bw6-761/fr/polynomial"
	"github.com/consensys/gnark-crypto/ecc/bw6-761/fr/sumcheck"
	"github.com/consensys/gnark-crypto/ecc/bw6-761/fr/test_vector_utils"
	"github.com/stretchr/testify/assert"
	"hash"
	"os"
	"path/filepath"
	"reflect"
	"strconv"
	"testing"
)

func TestNoGateTwoInstances(t *testing.T) {
	// Testing a single instance is not possible because the sumcheck implementation doesn't cover the trivial 0-variate case
	testNoGate(t, []fr.Element{four, three})
}

func TestNoGate(t *testing.T) {
	testManyInstances(t, 1, testNoGate)
}

func TestSingleMulGateTwoInstances(t *testing.T) {
	testSingleMulGate(t, []fr.Element{four, three}, []fr.Element{two, three})
}

func TestSingleMulGate(t *testing.T) {
	testManyInstances(t, 2, testSingleMulGate)
}

func TestSingleInputTwoIdentityGatesTwoInstances(t *testing.T) {

	testSingleInputTwoIdentityGates(t, []fr.Element{two, three})
}

func TestSingleInputTwoIdentityGates(t *testing.T) {

	testManyInstances(t, 2, testSingleInputTwoIdentityGates)
}

func TestSingleInputTwoIdentityGatesComposedTwoInstances(t *testing.T) {
	testSingleInputTwoIdentityGatesComposed(t, []fr.Element{two, one})
}

func TestSingleInputTwoIdentityGatesComposed(t *testing.T) {
	testManyInstances(t, 1, testSingleInputTwoIdentityGatesComposed)
}

func TestSingleMimcCipherGateTwoInstances(t *testing.T) {
	testSingleMimcCipherGate(t, []fr.Element{one, one}, []fr.Element{one, two})
}

func TestSingleMimcCipherGate(t *testing.T) {
	testManyInstances(t, 2, testSingleMimcCipherGate)
}

func TestATimesBSquaredTwoInstances(t *testing.T) {
	testATimesBSquared(t, 2, []fr.Element{one, one}, []fr.Element{one, two})
}

func TestShallowMimcTwoInstances(t *testing.T) {
	testMimc(t, 2, []fr.Element{one, one}, []fr.Element{one, two})
}
func TestMimcTwoInstances(t *testing.T) {
	testMimc(t, 93, []fr.Element{one, one}, []fr.Element{one, two})
}

func TestMimc(t *testing.T) {
	testManyInstances(t, 2, generateTestMimc(93))
}

func generateTestMimc(numRounds int) func(*testing.T, ...[]fr.Element) {
	return func(t *testing.T, inputAssignments ...[]fr.Element) {
		testMimc(t, numRounds, inputAssignments...)
	}
}

func TestSumcheckFromSingleInputTwoIdentityGatesGateTwoInstances(t *testing.T) {
	circuit := Circuit{Wire{
		Gate:      nil,
		Inputs:    []*Wire{},
		nbOutputs: 2,
	}}

	wire := &circuit[0]

	assignment := WireAssignment{&circuit[0]: []fr.Element{two, three}}

	claimsManagerGen := func() *claimsManager {
		manager := newClaimsManager(circuit, assignment, nil)
		manager.add(wire, []fr.Element{three}, five)
		manager.add(wire, []fr.Element{four}, six)
		return &manager
	}

	transcriptGen := sumcheck.NewMessageCounterGenerator(4, 1)

	proof := sumcheck.Prove(claimsManagerGen().getClaim(wire), transcriptGen())
	sumcheck.Verify(claimsManagerGen().getLazyClaim(wire), proof, transcriptGen())
}

var one, two, three, four, five, six fr.Element

func init() {
	one.SetOne()
	two.Double(&one)
	three.Add(&two, &one)
	four.Double(&two)
	five.Add(&three, &two)
	six.Double(&three)
}

var testManyInstancesLogMaxInstances = -1

func getLogMaxInstances(t *testing.T) int {
	if testManyInstancesLogMaxInstances == -1 {

		s := os.Getenv("GKR_LOG_INSTANCES")
		if s == "" {
			testManyInstancesLogMaxInstances = 5
		} else {
			var err error
			testManyInstancesLogMaxInstances, err = strconv.Atoi(s)
			if err != nil {
				t.Error(err)
			}
		}

	}
	return testManyInstancesLogMaxInstances
}

func testManyInstances(t *testing.T, numInput int, test func(*testing.T, ...[]fr.Element)) {
	fullAssignments := make([][]fr.Element, numInput)
	maxSize := 1 << getLogMaxInstances(t)

	t.Log("Entered test orchestrator, assigning and randomizing inputs")

	for i := range fullAssignments {
		fullAssignments[i] = make([]fr.Element, maxSize)
		setRandom(fullAssignments[i])
	}

	inputAssignments := make([][]fr.Element, numInput)
	for numEvals := maxSize; numEvals <= maxSize; numEvals *= 2 {
		for i, fullAssignment := range fullAssignments {
			inputAssignments[i] = fullAssignment[:numEvals]
		}

		t.Log("Selected inputs for test")
		test(t, inputAssignments...)
	}
}

func testNoGate(t *testing.T, inputAssignments ...[]fr.Element) {
	c := Circuit{
		{
			Inputs: []*Wire{},
			Gate:   nil,
		},
	}

	assignment := WireAssignment{&c[0]: inputAssignments[0]}

	proof := Prove(c, assignment, sumcheck.NewMessageCounter(1, 1))

	// Even though a hash is called here, the proof is empty

	if !Verify(c, assignment, proof, sumcheck.NewMessageCounter(1, 1)) {
		t.Error("Proof rejected")
	}
}

func testSingleMulGate(t *testing.T, inputAssignments ...[]fr.Element) {

	c := make(Circuit, 3)
	c[2] = Wire{
		Gate:   mulGate{},
		Inputs: []*Wire{&c[0], &c[1]},
	}

	assignment := WireAssignment{&c[0]: inputAssignments[0], &c[1]: inputAssignments[1]}.Complete(c)

	proof := Prove(c, assignment, sumcheck.NewMessageCounter(1, 1))

	if !Verify(c, assignment, proof, sumcheck.NewMessageCounter(1, 1)) {
		t.Error("Proof rejected")
	}

	if Verify(c, assignment, proof, sumcheck.NewMessageCounter(0, 1)) {
		t.Error("Bad proof accepted")
	}
}

func testSingleInputTwoIdentityGates(t *testing.T, inputAssignments ...[]fr.Element) {
	c := make(Circuit, 3)

	c[1] = Wire{
		Gate:   IdentityGate{},
		Inputs: []*Wire{&c[0]},
	}

	c[2] = Wire{
		Gate:   IdentityGate{},
		Inputs: []*Wire{&c[0]},
	}

	assignment := WireAssignment{&c[0]: inputAssignments[0]}.Complete(c)

	proof := Prove(c, assignment, sumcheck.NewMessageCounter(0, 1))

	if !Verify(c, assignment, proof, sumcheck.NewMessageCounter(0, 1)) {
		t.Error("Proof rejected")
	}

	if Verify(c, assignment, proof, sumcheck.NewMessageCounter(1, 1)) {
		t.Error("Bad proof accepted")
	}
}

func testSingleMimcCipherGate(t *testing.T, inputAssignments ...[]fr.Element) {
	c := make(Circuit, 3)

	c[2] = Wire{
		Gate:   mimcCipherGate{},
		Inputs: []*Wire{&c[0], &c[1]},
	}

	t.Log("Evaluating all circuit wires")
	assignment := WireAssignment{&c[0]: inputAssignments[0], &c[1]: inputAssignments[1]}.Complete(c)
	t.Log("Circuit evaluation complete")
	proof := Prove(c, assignment, sumcheck.NewMessageCounter(0, 1))
	t.Log("Proof complete")
	if !Verify(c, assignment, proof, sumcheck.NewMessageCounter(0, 1)) {
		t.Error("Proof rejected")
	}
	t.Log("Successful verification complete")
	if Verify(c, assignment, proof, sumcheck.NewMessageCounter(1, 1)) {
		t.Error("Bad proof accepted")
	}
	t.Log("Unsuccessful verification complete")
}

func testSingleInputTwoIdentityGatesComposed(t *testing.T, inputAssignments ...[]fr.Element) {
	c := make(Circuit, 3)

	c[1] = Wire{
		Gate:   IdentityGate{},
		Inputs: []*Wire{&c[0]},
	}
	c[2] = Wire{
		Gate:   IdentityGate{},
		Inputs: []*Wire{&c[1]},
	}

	assignment := WireAssignment{&c[0]: inputAssignments[0]}.Complete(c)

	proof := Prove(c, assignment, sumcheck.NewMessageCounter(0, 1))

	if !Verify(c, assignment, proof, sumcheck.NewMessageCounter(0, 1)) {
		t.Error("Proof rejected")
	}

	if Verify(c, assignment, proof, sumcheck.NewMessageCounter(1, 1)) {
		t.Error("Bad proof accepted")
	}
}

func mimcCircuit(numRounds int) Circuit {
	c := make(Circuit, numRounds+2)

	for i := 2; i < len(c); i++ {
		c[i] = Wire{
			Gate:   mimcCipherGate{},
			Inputs: []*Wire{&c[i-1], &c[0]},
		}
	}
	return c
}

func testMimc(t *testing.T, numRounds int, inputAssignments ...[]fr.Element) {
	//TODO: Implement mimc correctly. Currently, the computation is mimc(a,b) = cipher( cipher( ... cipher(a, b), b) ..., b)
	// @AlexandreBelling: Please explain the extra layers in https://github.com/ConsenSys/gkr-mimc/blob/81eada039ab4ed403b7726b535adb63026e8011f/examples/mimc.go#L10

	c := mimcCircuit(numRounds)

	t.Log("Evaluating all circuit wires")
	assignment := WireAssignment{&c[0]: inputAssignments[0], &c[1]: inputAssignments[1]}.Complete(c)
	t.Log("Circuit evaluation complete")

	proof := Prove(c, assignment, sumcheck.NewMessageCounter(0, 1))

	t.Log("Proof finished")
	if !Verify(c, assignment, proof, sumcheck.NewMessageCounter(0, 1)) {
		t.Error("Proof rejected")
	}

	t.Log("Successful verification finished")
	if Verify(c, assignment, proof, sumcheck.NewMessageCounter(1, 1)) {
		t.Error("Bad proof accepted")
	}
	t.Log("Unsuccessful verification finished")
}

func testATimesBSquared(t *testing.T, numRounds int, inputAssignments ...[]fr.Element) {
	// This imitates the MiMC circuit

	c := make(Circuit, numRounds+2)

	for i := 2; i < len(c); i++ {
		c[i] = Wire{
			Gate:   mulGate{},
			Inputs: []*Wire{&c[i-1], &c[0]},
		}
	}

	assignment := WireAssignment{&c[0]: inputAssignments[0], &c[1]: inputAssignments[1]}.Complete(c)

	proof := Prove(c, assignment, sumcheck.NewMessageCounter(0, 1))

	if !Verify(c, assignment, proof, sumcheck.NewMessageCounter(0, 1)) {
		t.Error("Proof rejected")
	}

	if Verify(c, assignment, proof, sumcheck.NewMessageCounter(1, 1)) {
		t.Error("Bad proof accepted")
	}
}

func setRandom(slice []fr.Element) {
	for i := range slice {
		slice[i].SetRandom()
	}
}

func generateTestProver(path string) func(t *testing.T) {
	return func(t *testing.T) {
		testCase, err := newTestCase(path)
		assert.NoError(t, err)
		testCase.Transcript.Update(0)
		proof := Prove(testCase.Circuit, testCase.FullAssignment, testCase.Transcript)
		assert.NoError(t, proofEquals(testCase.Proof, proof))
	}
}

func generateTestVerifier(path string) func(t *testing.T) {
	return func(t *testing.T) {
		testCase, err := newTestCase(path)
		assert.NoError(t, err)
		testCase.Transcript.Update(0)
		success := Verify(testCase.Circuit, testCase.InOutAssignment, testCase.Proof, testCase.Transcript)
		assert.True(t, success)

		testCase, err = newTestCase(path)
		assert.NoError(t, err)
		testCase.Transcript.Update(1)
		success = Verify(testCase.Circuit, testCase.InOutAssignment, testCase.Proof, testCase.Transcript)
		assert.False(t, success)
	}
}

func TestGkrVectors(t *testing.T) {

	testDirPath := "../../../../internal/generator/gkr/test_vectors"
	dirEntries, err := os.ReadDir(testDirPath)
	assert.NoError(t, err)
	for _, dirEntry := range dirEntries {
		if !dirEntry.IsDir() {

			if filepath.Ext(dirEntry.Name()) == ".json" {
				path := filepath.Join(testDirPath, dirEntry.Name())
				noExt := dirEntry.Name()[:len(dirEntry.Name())-len(".json")]

				t.Run(noExt+"_prover", generateTestProver(path))
				t.Run(noExt+"_verifier", generateTestVerifier(path))

			}
		}
	}
}

func proofEquals(expected Proof, seen Proof) error {
	if len(expected) != len(seen) {
		return fmt.Errorf("length mismatch %d ≠ %d", len(expected), len(seen))
	}
	for i, x := range expected {
		xSeen := seen[i]

		if xSeen.FinalEvalProof == nil {
			if seenFinalEval := x.FinalEvalProof.([]fr.Element); len(seenFinalEval) != 0 {
				return fmt.Errorf("length mismatch %d ≠ %d", 0, len(seenFinalEval))
			}
		} else {
			if err := test_vector_utils.SliceEquals(x.FinalEvalProof.([]fr.Element), xSeen.FinalEvalProof.([]fr.Element)); err != nil {
				return fmt.Errorf("final evaluation proof mismatch")
			}
		}
		if err := test_vector_utils.PolynomialSliceEquals(x.PartialSumPolys, xSeen.PartialSumPolys); err != nil {
			return err
		}
	}
	return nil
}

func BenchmarkGkrMimc(b *testing.B) {
	const N = 1 << 19
	fmt.Println("creating circuit structure")
	c := mimcCircuit(91)

	in0 := make([]fr.Element, N)
	in1 := make([]fr.Element, N)
	setRandom(in0)
	setRandom(in1)

	fmt.Println("evaluating circuit")
	assignment := WireAssignment{&c[0]: in0, &c[1]: in1}.Complete(c)

	//b.ResetTimer()
	fmt.Println("constructing proof")
	Prove(c, assignment, newMimcTranscript())
}

// TODO: Move into main package?
type hashTranscript struct {
	hash          hash.Hash
	nextAvailable bool
}

func newMimcTranscript() sumcheck.ArithmeticTranscript {
	return &hashTranscript{hash: mimc.NewMiMC()}
}

func (t *hashTranscript) hashToField() fr.Element {
	var res fr.Element
	res.SetBytes(t.hash.Sum(nil))
	return res
}

func toBytes(i interface{}) []byte {
	switch v := i.(type) {
	case fr.Element:
		return v.Marshal()
	case *fr.Element:
		return v.Marshal()
	}
	panic(fmt.Errorf("can't serialize type %T", i))
}

func (t *hashTranscript) Update(i ...interface{}) {
	if len(i) == 0 {
		t.hash.Write([]byte{})
	}
	for _, iI := range i {
		t.hash.Write(toBytes(iI))
	}
	t.nextAvailable = true
}

func (t *hashTranscript) Next(i ...interface{}) fr.Element {
	if !t.nextAvailable || len(i) != 0 {
		t.Update(i...)
	}
	t.nextAvailable = false
	return t.hashToField()
}

func (t *hashTranscript) NextN(n int, i ...interface{}) []fr.Element {
	if n <= 0 {
		return []fr.Element{}
	}
	res := make([]fr.Element, n)
	res[0] = t.Next(i...)
	for j := 1; j < n; j++ {
		res[j] = t.Next()
	}
	return res
}

func TestTopSortTrivial(t *testing.T) {
	c := make(Circuit, 2)
	c[0].Inputs = []*Wire{&c[1]}
	sorted := topologicalSort(c)
	assert.Equal(t, []*Wire{&c[1], &c[0]}, sorted)
}

func TestTopSortDeep(t *testing.T) {
	c := make(Circuit, 4)
	c[0].Inputs = []*Wire{&c[2]}
	c[1].Inputs = []*Wire{&c[3]}
	c[2].Inputs = []*Wire{}
	c[3].Inputs = []*Wire{&c[0]}
	sorted := topologicalSort(c)
	assert.Equal(t, []*Wire{&c[2], &c[0], &c[3], &c[1]}, sorted)
}

func TestTopSortWide(t *testing.T) {
	c := make(Circuit, 10)
	c[0].Inputs = []*Wire{&c[3], &c[8]}
	c[1].Inputs = []*Wire{&c[6]}
	c[2].Inputs = []*Wire{&c[4]}
	c[3].Inputs = []*Wire{}
	c[4].Inputs = []*Wire{}
	c[5].Inputs = []*Wire{&c[9]}
	c[6].Inputs = []*Wire{&c[9]}
	c[7].Inputs = []*Wire{&c[9], &c[5], &c[2]}
	c[8].Inputs = []*Wire{&c[4], &c[3]}
	c[9].Inputs = []*Wire{}

	sorted := topologicalSort(c)
	sortedExpected := []*Wire{&c[3], &c[4], &c[2], &c[8], &c[0], &c[9], &c[5], &c[6], &c[1], &c[7]}

	assert.Equal(t, sortedExpected, sorted)
}

type WireInfo struct {
	Gate   string `json:"gate"`
	Inputs []int  `json:"inputs"`
}

type CircuitInfo []WireInfo

var circuitCache = make(map[string]Circuit)

func getCircuit(path string) (Circuit, error) {
	path, err := filepath.Abs(path)
	if err != nil {
		return nil, err
	}
	if circuit, ok := circuitCache[path]; ok {
		return circuit, nil
	}
	var bytes []byte
	if bytes, err = os.ReadFile(path); err == nil {
		var circuitInfo CircuitInfo
		if err = json.Unmarshal(bytes, &circuitInfo); err == nil {
			circuit := circuitInfo.toCircuit()
			circuitCache[path] = circuit
			return circuit, nil
		} else {
			return nil, err
		}
	} else {
		return nil, err
	}
}

func (c CircuitInfo) toCircuit() (circuit Circuit) {
	circuit = make(Circuit, len(c))
	for i := range c {
		circuit[i].Gate = gates[c[i].Gate]
		circuit[i].Inputs = make([]*Wire, len(c[i].Inputs))
		for k, inputCoord := range c[i].Inputs {
			input := &circuit[inputCoord]
			circuit[i].Inputs[k] = input
		}
	}
	return
}

var gates map[string]Gate

func init() {
	gates = make(map[string]Gate)
	gates["identity"] = IdentityGate{}
	gates["mul"] = mulGate{}
	gates["mimc"] = mimcCipherGate{} //TODO: Add ark
}

type mimcCipherGate struct {
	ark fr.Element
}

func (m mimcCipherGate) Evaluate(input ...fr.Element) (res fr.Element) {
	var sum fr.Element

	sum.
		Add(&input[0], &input[1]).
		Add(&sum, &m.ark)

	res.Square(&sum)    // sum^2
	res.Mul(&res, &sum) // sum^3
	res.Square(&res)    //sum^6
	res.Mul(&res, &sum) //sum^7

	return
}

func (m mimcCipherGate) Degree() int {
	return 7
}

type PrintableProof []PrintableSumcheckProof

type PrintableSumcheckProof struct {
	FinalEvalProof  interface{}     `json:"finalEvalProof"`
	PartialSumPolys [][]interface{} `json:"partialSumPolys"`
}

func unmarshalProof(printable PrintableProof) (Proof, error) {
	proof := make(Proof, len(printable))
	for i := range printable {
		finalEvalProof := []fr.Element(nil)

		if printable[i].FinalEvalProof != nil {
			finalEvalSlice := reflect.ValueOf(printable[i].FinalEvalProof)
			finalEvalProof = make([]fr.Element, finalEvalSlice.Len())
			for k := range finalEvalProof {
				if _, err := test_vector_utils.SetElement(&finalEvalProof[k], finalEvalSlice.Index(k).Interface()); err != nil {
					return nil, err
				}
			}
		}

		proof[i] = sumcheck.Proof{
			PartialSumPolys: make([]polynomial.Polynomial, len(printable[i].PartialSumPolys)),
			FinalEvalProof:  finalEvalProof,
		}
		for k := range printable[i].PartialSumPolys {
			var err error
			if proof[i].PartialSumPolys[k], err = test_vector_utils.SliceToElementSlice(printable[i].PartialSumPolys[k]); err != nil {
				return nil, err
			}
		}
	}
	return proof, nil
}

type TestCase struct {
	Circuit         Circuit
	Transcript      sumcheck.ArithmeticTranscript
	Proof           Proof
	FullAssignment  WireAssignment
	InOutAssignment WireAssignment
}

type TestCaseInfo struct {
	Hash    string          `json:"hash"`
	Circuit string          `json:"circuit"`
	Input   [][]interface{} `json:"input"`
	Output  [][]interface{} `json:"output"`
	Proof   PrintableProof  `json:"proof"`
}

type ParsedTestCase struct {
	FullAssignment  WireAssignment
	InOutAssignment WireAssignment
	Proof           Proof
	Hash            *test_vector_utils.HashMap
	Circuit         Circuit
}

var parsedTestCases = make(map[string]*ParsedTestCase)

func newTestCase(path string) (*TestCase, error) {
	path, err := filepath.Abs(path)
	if err != nil {
		return nil, err
	}
	dir := filepath.Dir(path)

	parsedCase, ok := parsedTestCases[path]
	if !ok {
		var bytes []byte
		if bytes, err = os.ReadFile(path); err == nil {
			var info TestCaseInfo
			err = json.Unmarshal(bytes, &info)
			if err != nil {
				return nil, err
			}

			var circuit Circuit
			if circuit, err = getCircuit(filepath.Join(dir, info.Circuit)); err != nil {
				return nil, err
			}
			var _hash *test_vector_utils.HashMap
			if _hash, err = test_vector_utils.GetHash(filepath.Join(dir, info.Hash)); err != nil {
				return nil, err
			}
			var proof Proof
			if proof, err = unmarshalProof(info.Proof); err != nil {
				return nil, err
			}

			fullAssignment := make(WireAssignment)
			inOutAssignment := make(WireAssignment)

			sorted := topologicalSort(circuit)

			inI, outI := 0, 0
			for _, w := range sorted {
				var assignmentRaw []interface{}
				if w.IsInput() {
					if inI == len(info.Input) {
						return nil, fmt.Errorf("fewer input in vector than in circuit")
					}
					assignmentRaw = info.Input[inI]
					inI++
				} else if w.IsOutput() {
					if outI == len(info.Output) {
						return nil, fmt.Errorf("fewer output in vector than in circuit")
					}
					assignmentRaw = info.Output[outI]
					outI++
				}
				if assignmentRaw != nil {
					var wireAssignment []fr.Element
					if wireAssignment, err = test_vector_utils.SliceToElementSlice(assignmentRaw); err != nil {
						return nil, err
					}

					fullAssignment[w] = wireAssignment
					inOutAssignment[w] = wireAssignment
				}
			}

			fullAssignment.Complete(circuit)

			for _, w := range sorted {
				if w.IsOutput() {

					if err = test_vector_utils.SliceEquals(inOutAssignment[w], fullAssignment[w]); err != nil {
						return nil, fmt.Errorf("assignment mismatch: %v", err)
					}

				}
			}

			parsedCase = &ParsedTestCase{
				FullAssignment:  fullAssignment,
				InOutAssignment: inOutAssignment,
				Proof:           proof,
				Hash:            _hash,
				Circuit:         circuit,
			}

			parsedTestCases[path] = parsedCase
		} else {
			return nil, err
		}
	}

	return &TestCase{
		Circuit:         parsedCase.Circuit,
		Transcript:      &test_vector_utils.MapHashTranscript{HashMap: parsedCase.Hash},
		FullAssignment:  parsedCase.FullAssignment,
		InOutAssignment: parsedCase.InOutAssignment,
		Proof:           parsedCase.Proof,
	}, nil
}

type mulGate struct{}

func (g mulGate) Evaluate(element ...fr.Element) (result fr.Element) {
	result.Mul(&element[0], &element[1])
	return
}

func (g mulGate) Degree() int {
	return 2
}
