# 인퍼널 섀도우
인퍼널 섀도우 사용시 인퍼널 섀도우로 자동 타겟팅 해주는 애드온을 만들고 있습니다.

타겟을 변경 하는 api가 없다보니 Ebisuke제작자분의 enhancedtargetlock이 사용하는 방법으로 일단 제작은 해봤습니다.

마우스 커서를 대상에게 이동을 하고 마우스모드로 잠시 전환 이후 다시 키보드모드로 전환 하는 방식인데요,
* 키보드모드를 사용하고있어야함 (마우스모드 호환x)
* 마우스모드로 잠깐씩 바뀌기때문에 키 바인딩 (이동키, 스킬키) 등등 키보드모드와 마우스모드를 동일하게 바꾸고 실행하는것을 추천
* 무조건 타겟 락 (기본 capslock) 을 설정해야함

사용방법:
* 만약 현 타겟이 이미 인퍼널이라면 아무 동작도 없음
* 만약 현 타겟이 인퍼널이 아니라면 인퍼널 섀도우 스킬 을 다시 누르면 주변 인퍼널 새도우 검색
* 검색 성공하면 인퍼널 섀도우로 타겟 락 시도
* 만약 주변에 인퍼널이 없고, 보스가 타겟이 아니라면 주변 보스 탐색 이후 보스에게 타겟 락 시도
* `/infernal off` 혹은 `/인퍼널 off` 명령어로 보스 탐색 기능 끌수있음
* off상태에서는 주변에 인퍼널이 있을시 인퍼널 타겟팅만 시도함
* on 상태에서는 주변에 인퍼널이 없을시 보스 타겟팅까지 시도함

간단요약: 인퍼널 스킬 마구 눌러

-----------
# Infernal Shadow
This is an infernal shadow auto-target addon.

Since there is no good API for target switching, I am using Ebisuke's enhancedtargetlock code and method.

It utilizes temporarily swapping to mouse mode and attempting to move mouse around until a desired target is locked on,
which user is switched back to keyboard mode.
* Only works on keyboard mode
* Requires target lock enabled (capslock by default)
* Recommended that keybinds for skill and movement is same in mouse and keyboard mode

How to use:
* Press on infernal shadow's hotkey to trigger search
* If target is not already infernal shadow, this will attempt to change target to nearest infernal shadow
* If there is no nearby infernal shadow, then instead try to lock on to nearest boss
* `/infernal off` can be used to disable nearby boss search
* When in `off` state, addon only searches for nearby infernal shadow
* When in `on` state, addon does double duty of also searching for nearby boss.

Thus, by repeatedly pressing on infernal shadow hotkey, the user can easily swap to the shadow
and swap back to the boss once the shadow is gone.