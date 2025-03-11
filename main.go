package main

import (
	"context"
	"flag"
	"fmt"
	"github.com/OnlyPiglet/block_ip_set/pkg"
	"io/ioutil"
	"log"
	"net"
	"os"
	"strings"

	"github.com/go-redis/redis/v8"
	"gopkg.in/yaml.v3"
)

var (
	filePath = flag.String("c", "", "文本文件路径（包含ip列表）")
	action   = flag.String("action", "", "操作类型：black/white")
)

type Config struct {
	Redis struct {
		Addr     string `yaml:"addr"`
		Password string `yaml:"password"`
		DB       int    `yaml:"db"`
	} `yaml:"redis"`
}

func main() {
	flag.Parse()

	// 1. 参数校验
	if *filePath == "" || (*action != "black" && *action != "white") {
		log.Fatal("参数错误：必须提供 -c 和有效的 action（black/white）")
	}

	// 2. 读取并解析配置文件[9](@ref)
	config := loadConfig("config.yaml")

	// 3. 初始化Redis客户端[12](@ref)
	rdb := redis.NewClient(&redis.Options{
		Addr:     config.Redis.Addr,
		Password: config.Redis.Password,
		DB:       config.Redis.DB,
	})

	// 4. 处理IP列表
	processIPs(rdb)
}

func loadConfig(path string) *Config {
	var config Config
	data, err := ioutil.ReadFile(path)
	if err != nil {
		log.Fatalf("读取配置文件失败: %v", err)
	}

	if err := yaml.Unmarshal(data, &config); err != nil {
		log.Fatalf("解析配置文件失败: %v", err)
	}
	return &config
}

func processIPs(rdb *redis.Client) {
	// 读取文件内容[2](@ref)
	content, err := os.ReadFile(*filePath)
	if err != nil {
		log.Fatal("读取文件失败：", err)
	}

	// 分割IP地址
	ipList := strings.Split(strings.TrimSpace(string(content)), ",")

	// 设置位图值
	bitValue := 0
	if *action == "black" {
		bitValue = 1
	}

	ctx := context.Background()
	for _, ipStr := range ipList {
		ip := net.ParseIP(strings.TrimSpace(ipStr))
		if ip == nil {
			log.Printf("无效IP地址：%s", ipStr)
			continue
		}

		// IPv4转换[9](@ref)
		ipv4 := ip.To4()
		if ipv4 == nil {
			log.Printf("非IPv4地址：%s", ipStr)
			continue
		}

		offset, err := pkg.OptimizedIPToASCII(ipv4.String())
		if err != nil {
			log.Printf("IPV 转换失败位图: %s", ipStr)
		}

		// 执行Redis操作[12](@ref)
		if err := rdb.SetBit(ctx, "block_ip", int64(offset), bitValue).Err(); err != nil {
			log.Printf("Redis操作失败：%v", err)
		} else {
			fmt.Printf("成功设置 %s -> %d 为 %d\n", ipStr, offset, bitValue)
		}
	}
}
