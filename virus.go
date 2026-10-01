package main

import (
	"fmt"
	"math"
	"runtime"
	"sync"
)

// --- Global Stressor Components ---
// Define a very large array to force CPU cache thrashing.
// 100 Megabytes of data is a good stressor.
const ArraySize = 100 * 1024 * 1024 // 100 MB
var largeData [ArraySize]float64

// Initialize the large data structure once at startup
func init() {
	// Pre-populate the array with some variable data to ensure it's not zero-value memory
	for i := range largeData {
		largeData[i] = float64(i%100) / 10.0 // Simple pattern initialization
	}
}

func cpuBurner(id int, wg *sync.WaitGroup) {
	defer wg.Done()

	var accumulator float64 = 0.0
	var workCounter int64 = 0

	for {
		// 1. CORE MATH LOAD >> Original Work)
		x := float64(workCounter%2000+1) / 10.0
		term1 := math.Sin(x * 1.5)
		term2 := math.Cos(x * 0.8)
		term3 := math.Pow(x, 3.0)
		result := (term1 * term2 * term3) / (x + 0.001)
		result += float64(workCounter%100) / 100.0
		accumulator += result
		workCounter++

		// 2. MEMORY THROTTLING LOAD (NEW AGGRESSIVE STRESSOR)
		// Iterate over the entire massive array in every cycle.
		// This forces the CPU to constantly reload data into its caches.
		var memoryStressSum float64 = 0.0
		for i := 0; i < ArraySize; i++ {
			// Simple operation on the pre-existing data is enough to cause contention
			memoryStressSum += largeData[i] * (float64(i) / float64(ArraySize))
		}
		// Add the memory stress result to the accumulator to reflect the work done
		accumulator += (memoryStressSum / float64(ArraySize))

		// Status reporting only from the first worker, and rarely
		if id == 0 && workCounter%(5_000_000/2) == 0 { // Adjusted divisor due to increased work
			fmt.Printf("[CPU Hog] Worker %d | Cycle %d | Acc: %.4f\n", id, workCounter, accumulator)
		}
	}
}

func main() {
	numCPU := runtime.NumCPU()
	// Ensure Go utilizes all available cores aggressively
	runtime.GOMAXPROCS(numCPU)

	fmt.Println("=====================================================")
	fmt.Println(" DEFINITIVE, PEAK CPU SATURATION + MEMORY THRASHER MODE ")
	fmt.Println("-----------------------------------------------------")
	fmt.Printf("System tuned to utilize %d CPU cores.\n", numCPU)
	fmt.Println("Loading data structure... (This takes time for initial fill)")
	fmt.Println("Press Ctrl+C to stop.")
	fmt.Println("=====================================================")

	var wg sync.WaitGroup

	// Launch one heavy worker per CPU core
	for i := 0; i < numCPU; i++ {
		wg.Add(1)
		go cpuBurner(i, &wg)
	}

	wg.Wait() // Will never finish (infinite loops)
}
