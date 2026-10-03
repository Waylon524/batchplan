# BatchPlan 中文上手指南

## 它解决什么问题

把有顺序的数据拆成小批次时，通常要同时满足「最多多少条」「最多多少字节」「最多多少 token」等限制。BatchPlan 接收你提供的整数成本，按照固定规则分批，保留原始位置和 ID，并能独立核验结果。

它不计算 token，不调用 API，不写入数据库。成本和限制由使用者提供；三个案例使用模拟数据和示例限制，不代表任何服务商的真实配额。

## 先运行

在已安装 MoonBit 和 Node.js 22.16 以上版本的环境中，进入本目录：

```sh
moon test --target js
moon run cmd/main --target js -- plan < examples/embedding_requests.json
moon run cmd/main --target js -- csv < examples/database_bulk.json
bash scripts/check.sh
```

`plan` 输出分批清单，`csv` 输出原始记录与批次的对应关系。`verify` 输入还要包含原始 items、budget 和待检查的 manifest。三个案例的预期结果见 `examples/README.md`。

## 读懂结果

- `indices`：这批对应原始输入中的哪些位置，从 0 开始
- `item_ids`：对应的记录 ID
- `totals`：按 dimensions 顺序排列的总成本，已经包含 envelope 和每条记录的额外开销
- `batch_overhead`：每个非空批次固定增加的成本
- `item_overhead`：每条记录固定增加的成本
- `group`：相邻且相同的 group 必须一起分配；同一 group 不允许隔开后重新出现

算法从左到右装入当前批次，放不下就另开一批，不重新排序，也不宣称批次数最少。

## 建议亲自做的三个小实验

1. 复制 embeddings 案例，把第一条的 tokens 改成 101，观察 `oversized_item` 错误
2. 复制 database 案例，把 `max_items` 改成 2，观察三条一组的数据为什么不能拆开
3. 给 `verify` 一个真实计划，再改动其中一个 totals，观察 `totals_mismatch`

建议自己运行并修改这些案例，确认理解成本、固定开销、保序分批和错误信息。

## 开发与许可

仓库命名空间为 `Waylon524/batchplan`，采用 MIT 许可证，见项目根目录 LICENSE。当前尚未发布 Mooncakes 包。完整检查方法及已验证范围见 `VERIFICATION.md`；贡献前请阅读 `CONTRIBUTING.md`。
