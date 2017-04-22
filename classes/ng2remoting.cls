global class ng2remoting {
	@RemoteAction
    global static List<Account> getAccount() {
        return [Select Id, Name from Account limit 10];
    }
}