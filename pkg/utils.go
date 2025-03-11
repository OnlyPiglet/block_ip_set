package pkg

func OptimizedIPToASCII(ip string) (int, error) {
	// 计算总和
	sum := 0
	for _, c := range ip {
		if c != '.' {
			sum += int(c)
		}
	}
	return sum, nil
}
