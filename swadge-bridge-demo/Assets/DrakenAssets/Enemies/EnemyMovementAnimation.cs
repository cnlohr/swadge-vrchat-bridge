using UdonSharp;
using UnityEngine;

namespace DrakenStark
{
    [UdonBehaviourSyncMode(BehaviourSyncMode.None)]
    public class EnemyMovementAnimation : UdonSharpBehaviour
    {
        [SerializeField] private Transform _rootTransform = null;
        [SerializeField] private Animator _animator = null;
        private Vector3 _lastPos = Vector3.zero;
        [SerializeField] private float _frequency = 0.25f;
        [SerializeField] private float _scaling = 3f;

        private void Start()
        {
            _lastPos = _rootTransform.position;
            SendCustomEventDelayedSeconds("_periodic", _frequency);
        }

            //Debug.LogWarning(_rootTransform.name + " Speed: " + (Vector3.Distance(_rootTransform.position, _lastPos) * _scaling));
            //_animator.SetBool("Walking", (Vector3.Distance(_rootTransform.position, _lastPos) / _frequency) > 0);
        public void _periodic()
        {
            _animator.SetFloat("WalkSpeed",Vector3.Distance(_rootTransform.position, _lastPos) * _scaling);
            _lastPos = _rootTransform.position;
            SendCustomEventDelayedSeconds("_periodic", _frequency);
        }
    }
}