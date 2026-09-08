package com.xieliu.agile;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

/**
 * 协流 Agile 后端主入口。
 *
 * <p>当前为极简脚手架，仅保留主类；后续将按《协流Agile_MVP开发文档_v1.0.md》
 * 逐步扩展为模块化单体架构（按领域拆分模块，统一 API 网关层）。</p>
 */
@SpringBootApplication
public class AgileApplication {

    public static void main(String[] args) {
        SpringApplication.run(AgileApplication.class, args);
    }
}
