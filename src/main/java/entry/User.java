package entry;

import com.alibaba.fastjson.annotation.JSONField;
import com.alibaba.fastjson.annotation.JSONType;
import lombok.Data;

import java.util.Date;
@Data
public class User {
    private String name;
    @JSONField
    private Date date;

    public User() {
        this.name = name;
        this.date = date;
    }
}
