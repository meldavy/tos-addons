# 자동 봉헌 애드온
`/afk` 명령어를 사용하게되면 다음 봉헌 이벤트 시작시 실버가 다 소진되던가 봉헌이 종료될때까지 자동 봉헌을 합니다.

여신의 가호 이벤트가 종료되면 애드온이 비활성화 설정이 되며, 비활성화 상태에서 봉헌이 시작되도 자동 봉헌이 실행되지 않습니다.

즉, `/afk` 명령어로 애드온 활성화를 하는건 1회성이며, 활성화 된 상태에서 다음 진행되는 봉헌만 자동으로 돌려줍니다. 고의적으로 애드온을 활성화 하고 잠수를 할때만 자동봉헌이 되고, 실수로 실버 소모가 발생하지 않게끔 구현이 된것입니다.

# Auto Goddess Protection Addon
After using the `/afk` command, the addon becomes enabled.

When in enabled state, the addon auto-runs the next goddess protection donation event until either user runs out of silver of the event ends.

Once the event ends, the addon becomes disabled. Thus, until it is turned back on again using `/afk` command, the addon does not perform auto donation until renabled. This is to ensure that the addon only performs auto donation only when the user willingly uses the `/afk` command, preventing any accidental silver consumption due to the addon.