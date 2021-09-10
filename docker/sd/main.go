package main

import (
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"net/url"
	"sd/xredis"

	"github.com/go-redis/redis/v8"
	"github.com/labstack/echo/v4"
	"github.com/spf13/viper"
)

type Node struct {
	Type string `redis:"-"`
	Name string `redis:"name"`
	IP   string `redis:"ip"`
	Port string `redis:"port"`
}

func main() {
	viper.SetEnvPrefix("")
	viper.AutomaticEnv()
	ctx := context.Background()
	addr := viper.GetString("redis_addr")
	parsed, err := url.Parse(addr)
	if err != nil || parsed.Scheme != "redis" {
		fmt.Printf("error parsing REDIS_ADDR: %s [%v]\n", addr, err)
		return
	}
	config := &redis.Options{
		Addr:     parsed.Host,
		Password: viper.GetString("redis_password"),
	}
	client := redis.NewSentinelClient(config)

	var targets []Node
	res := client.Masters(ctx).Val()
	if len(res) > 0 {
		fmt.Printf("sd: sentinel mode: %s\n", addr)
		out := res[0].([]interface{})
		var master Node
		err := xredis.ScanToStruct(out, &master, "redis")
		if err != nil {
			fmt.Printf("error: %v\n", err)
			return
		}
		fmt.Printf("master: %v\n", master)
		master.Type = "master"
		targets = append(targets, master)

		res = client.Slaves(ctx, master.Name).Val()
		for _, s := range res {
			out := s.([]interface{})
			var slave Node
			err = xredis.ScanToStruct(out, &slave, "redis")
			if err != nil {
				fmt.Printf("error: %v\n", err)
			}
			slave.Type = "slave"
			fmt.Printf("slave: %v\n", slave)
			targets = append(targets, slave)
		}
	} else { // Single node
		fmt.Printf("sd: standalone mode: %s\n", addr)
		targets = append(targets, Node{
			Type: "master",
			IP:   parsed.Hostname(),
			Port: parsed.Port(),
		})
	}
	e := echo.New()
	e.GET("/targets", targetsHandler(targets))
	_ = e.Start(":9122")
}

type StaticConfig struct {
	Targets []string          `json:"targets"`
	Labels  map[string]string `json:"labels,omitempty"`
}

type TargetResponse []StaticConfig

func targetsHandler(targets []Node) echo.HandlerFunc {
	return func(c echo.Context) error {
		response := TargetResponse{}
		for _, node := range targets {
			response = append(response, StaticConfig{
				Targets: []string{fmt.Sprintf("%s:%s", node.IP, node.Port)},
				Labels: map[string]string{
					"__meta_redis_node_type": node.Type,
				},
			})
		}
		data, _ := json.Marshal(response)
		return c.Blob(http.StatusOK, "application/json", data) // Prometheus bug #9017
	}
}
