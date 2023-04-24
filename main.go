package main

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
	"strconv"
	"time"

	"github.com/aws/aws-lambda-go/lambda"
	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/costexplorer"
	"github.com/aws/aws-sdk-go-v2/service/costexplorer/types"
)

var UTC = time.UTC
var TIME_FORMAT = "2006-01-02"
var UNBLENDED_COST = "UnblendedCost"
var NOTIFICATION_USER_NAME = "AWS Billing Reporter"

var SLACK_WEBHOOK_URL, COST_EXPLORE_URL, CLOUD_WATCH_URL string

func main() {
	lambda.Start(handler)
}

func handler() {

	LoadEnvVariables()

	ctx := context.Background()

	now := time.Now().In(UTC)
	today := now.Format(TIME_FORMAT)
	month := now.Month()
	start := time.Date(now.Year(), now.Month(), 1, 0, 0, 0, 0, UTC).Format(TIME_FORMAT)
	end := time.Date(now.Year(), now.Month()+1, 1, 0, 0, 0, 0, UTC).Format(TIME_FORMAT)

	cfg, err := config.LoadDefaultConfig(ctx)
	if err != nil {
		PostErrorMessage(today, int(month))
		log.Fatalln(err)
	}
	ce := costexplorer.NewFromConfig(cfg)

	costAndUsage, err := ce.GetCostAndUsage(ctx, &costexplorer.GetCostAndUsageInput{
		Granularity: types.GranularityMonthly,
		Metrics:     []string{UNBLENDED_COST},
		TimePeriod: &types.DateInterval{
			Start: aws.String(start),
			End:   aws.String(end),
		},
	})
	if err != nil {
		PostErrorMessage(today, int(month))
		log.Fatalln(err)
	}

	var total float64
	for _, result := range costAndUsage.ResultsByTime {
		amount, err := strconv.ParseFloat(*result.Total[UNBLENDED_COST].Amount, 64)
		if err != nil {
			PostErrorMessage(today, int(month))
			log.Fatalln(err)
		}
		total += amount
	}

	PostBillingMessage(today, int(month), total)
}

func LoadEnvVariables() {
	if SLACK_WEBHOOK_URL == "" && COST_EXPLORE_URL == "" && CLOUD_WATCH_URL == "" {
		SLACK_WEBHOOK_URL = os.Getenv("SLACK_WEBHOOK_URL")
		COST_EXPLORE_URL = os.Getenv("COST_EXPLORE_URL")
		CLOUD_WATCH_URL = os.Getenv("CLOUD_WATCH_URL")
	}
}

const ERROR_MESSAGE = `
%s 時点での %d 月のAWSの利用料金の通知処理中に、
エラーが発生しました。
<%s|利用料金>と<%s|エラー内容>を確認してください。
`

func PostErrorMessage(today string, month int) {

	var payload bytes.Buffer
	if err := json.NewEncoder(&payload).Encode(SlackNotification{
		UserName: NOTIFICATION_USER_NAME,
		Text:     fmt.Sprintf(ERROR_MESSAGE, today, month, COST_EXPLORE_URL, CLOUD_WATCH_URL),
	}); err != nil {
		log.Fatalln(err)
	}
}

const BILLING_MESSAGE = `
%s 時点での %d 月のAWSの利用料金は
%f USD になります。
詳細は<%s|こちら>を確認してください。
`

func PostBillingMessage(today string, month int, total float64) {

	var payload bytes.Buffer
	if err := json.NewEncoder(&payload).Encode(SlackNotification{
		UserName: NOTIFICATION_USER_NAME,
		Text:     fmt.Sprintf(BILLING_MESSAGE, today, month, total, COST_EXPLORE_URL),
	}); err != nil {
		PostErrorMessage(today, int(month))
		log.Fatalln(err)
	}

	_, err := http.Post(SLACK_WEBHOOK_URL, "application/json", &payload)
	if err != nil {
		PostErrorMessage(today, int(month))
		log.Fatalln(err)
	}
}

type SlackNotification struct {
	UserName string `json:"username"`
	Text     string `json:"text"`
}
