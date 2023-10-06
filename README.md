# survey-sh

OSS Gateワークショップで使用する、アンケートファイル (YAML形式) を出力するスクリプト

## 使用例

    $ cd path/to/survey-sh
    $ ./survey.sh -t beginner -u alice
    (beginner) survey:

引数は省略可能です。

    $ ./survey.sh
    survey% Input your usertype
    survey> beginner
    (beginner) survey:

この場合は、スクリプト起動後にユーザータイプを入力します。(beginnerもしくはsupporter)

スクリプトのコマンド一覧は、`?` (`h`, `help`) を参照してください。

    (beginner) survey: ?

アンケートファイルは、`beginner-alice.yaml`のように出力されます。
