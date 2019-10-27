package app

type PushManager interface {
	IsSubscribed() bool
	Subscribe(serverPublicKey string) (string, error)
	UnSubscribe() error
	// Handle(f func(event string))
	// Show(n PushNotification)
}

// type PushNotification struct {
// 	Title   string
// 	Body    string
// 	Icon    string
// 	Badge   string
// 	OnClick func()
// }
