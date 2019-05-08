package server;

import entry.User;
import org.springframework.stereotype.Service;

@Service
public class UserServer {
    public static User user = new User();

    public static void main(String[] args) {
        user.getClass().getName();
    }


}
